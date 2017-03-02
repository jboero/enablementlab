## Test Case Environment

### Single node

### Single Vault Enterprise cluster 

In order to set up Vault working in Cluster mode, an HA Backend is required. The recommended backend is Consul, although there are others supported such as DynamoDB. Please refer to the *Backend Reference* on [https://www.vaultproject.io/docs/config/](https://www.vaultproject.io/docs/config/) for more information.

Vault Enterprise is distributed as a pre-compiled binary, so in order to run in on a (EL, or other systemd based) system a Systemd unit file is required. The following example can be used as reference:

*[Unit]*

*Description=Vault server*

*Requires=basic.target network.target*

*After=basic.target network.target*

*[Service]*

*User=vault*

*Group=vault*

*PrivateDevices=yes*

*PrivateTmp=yes*

*ProtectSystem=full*

*ProtectHome=read-only*

*SecureBits=keep-caps*

*Capabilities=CAP_IPC_LOCK+ep*

*CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK*

*NoNewPrivileges=yes*

*Environment=GOMAXPROCS=1*

*ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.json*

*KillSignal=SIGINT*

*TimeoutStopSec=30s*

*Restart=on-failure*

*StartLimitInterval=60s*

*StartLimitBurst=3*

*[Install]*

*WantedBy=multi-user.target*

The suggested architecture, is to run a three-node cluster to avoid split-brain scenarios and maintain quorum. 

A basic configuration file could be as follows:

```json
{
	"backend": {
		"consul": {
			"address": "fqdn.of.consul.server",
			"path": "kvstorepath"
		}
	},
	"listener": {
		"tcp": {
			"address": "0.0.0.0:8200",
			"tls_cert_file": "/etc/ssl/vault/vault.crt",
			"tls_disable": 0,
			"tls_key_file": "/etc/ssl/vault/vault.key"
		}
	}
}```

Where the backend configuration specifies where to store the data. Data will be stored encrypted at rest, and only available to vault after the unseal process.

Data will be encrypted at all times (including transit via TLS), as described by the diagram below:

![image alt text](https://www.vaultproject.io/assets/images/layers-368ccce4.png)

In order to enable the Enterprise UI, set the ui parameter to true, as described in [https://www.vaultproject.io/docs/config/index.html#ui](https://www.vaultproject.io/docs/config/index.html#ui).

Upon configuring the three nodes to use the same storage backend, the Vault should be initialized on one of the nodes. Then simply unseal the remaining nodes to make them available, as described in Appendix B, section VE-INIT-001.

The first node will become active:

[user@node1 ~]$ vault status

Sealed: false

Key Shares: 5

Key Threshold: 3

Unseal Progress: 0

Unseal Nonce: Version: 0.6.5+ent

Cluster Name: vault-cluster-79c89975

Cluster ID: f09164ad-39da-9bff-6f7e-98f0251b2e3f

High-Availability Enabled: true

**	Mode: active**

	Leader: https://172.16.155.182:8200

As the remaining ones will be on Standby:

[user@node2 ~]$ vault status

Sealed: false

Key Shares: 5

Key Threshold: 3

Unseal Progress: 0

Unseal Nonce: Version: 0.6.5+ent

Cluster Name: vault-cluster-79c89975

Cluster ID: f09164ad-39da-9bff-6f7e-98f0251b2e3f

High-Availability Enabled: true

	Mode: standby

	Leader: https://172.16.155.182:8200

### Two Vault Enterprise clusters 

These instructions are for configuring two 3 node Vault cluster with Consul storage backend for high availability, with replication between clusters

# Appendix B

## Test Case Specifications

<table>
  <tr>
    <td>Test Case</td>
    <td>VE-INIT-001</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Verify single Vault cluster installation, perform initialization</td>
  </tr>
  <tr>
    <td>Setup</td>
    <td>Perform single Vault cluster installation per Appendix A</td>
  </tr>
  <tr>
    <td>Command/Input</td>
    <td>Initialize Vault using command linevault init -key-shares=5 -key-threshold=3 
Record and store the the initial root token and 5 unseal keys.
Perform unseal operation using 3 of the unseal keys.vault unseal <unseal key 1>vault unseal <unseal key 2>vault unseal <unseal key 3>
Check Vault status:vault status</td>
  </tr>
  <tr>
    <td>Expected Results</td>
    <td>Vault should initialize successfully and return initial root token and unseal keys.

Vault status should show that Vault is active and unsealed.</td>
  </tr>
  <tr>
    <td>Pass (Y/N)</td>
    <td></td>
  </tr>
  <tr>
    <td>Actual Results</td>
    <td></td>
  </tr>
</table>


<table>
  <tr>
    <td>Test Case</td>
    <td>VE-WEB-002</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Verify web interface operation to seal, unseal Vault</td>
  </tr>
  <tr>
    <td>Setup</td>
    <td>Perform single Vault cluster installation per Appendix A and successful completion of VE-INIT-001</td>
  </tr>
  <tr>
    <td>Command/Input</td>
    <td>Login to web interface at http://<server IP>/ui/
Authenticate using initial root token stored from VE-INIT-001
Navigate to ‘Manage’ tab
Click ‘Seal Vault’ button, and Confirm
Using web interface, provide 3 of the unseal keys in successive fashion to unseal Vault
Once Vault is unsealed, re-authenticate using the initial root token to verify Vault status

</td>
  </tr>
  <tr>
    <td>Expected Results</td>
    <td>Vault web interface should allow for root token authentication.
Vault web interface should perform seal and unseal operations successfully.

Upon completion, Vault status should show that Vault is active and unsealed.</td>
  </tr>
  <tr>
    <td>Pass (Y/N)</td>
    <td></td>
  </tr>
  <tr>
    <td>Actual Results</td>
    <td></td>
  </tr>
</table>


<table>
  <tr>
    <td>Test Case</td>
    <td>VE-TLS-003</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Configure Vault to secure communication using TLS.</td>
  </tr>
  <tr>
    <td>Setup</td>
    <td>In Vault’s configuration file, under the tcp listener block, ensure the following parameters are configured as follows:
tls_disable = 0
tls_cert_file = ‘/path/to/vault.crt’
tls_key_file = ‘/path/to/vault.key’

It is expected for Mastercard to provide appropriate certificates, signed by their internal Certificate Authority. The Vault service must be restarted, and the Vault must be unsealed before running the following tests.</td>
  </tr>
  <tr>
    <td>Command/Input</td>
    <td>From any host, ensure that the proper environment variables are set:

VAULT_TOKEN
VAULT_CACERT
VAULT_ADDR (to HTTPS host)

Run vault status
</td>
  </tr>
  <tr>
    <td>Expected Results
</td>
    <td>The command should return an output similar to the one below:
[user@host ~]# vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0
Version: 0.6.2
Cluster Name: vault-cluster-bd48d4b7
Cluster ID: f706c976-2758-7805-ac8d-f76767da0ecd

High-Availability Enabled: true
	Mode: active
	Leader: https://172.16.74.151:8200

If the VAULT_HOST variable is changed to http, the following response should be expected:

[user@host ~]# vault status
Error checking seal status: Get http://127.0.0.1:8200/v1/sys/seal-status: malformed HTTP response "\x15\x03\x01\x00\x02\x02"

</td>
  </tr>
  <tr>
    <td>Pass (Y/N)</td>
    <td></td>
  </tr>
  <tr>
    <td>Actual Results</td>
    <td></td>
  </tr>
</table>


<table>
  <tr>
    <td>Test Case</td>
    <td>VE-FUNC-004</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Perform CRUD secret operations. Verify how basic policies manage access to secrets.</td>
  </tr>
  <tr>
    <td>Setup</td>
    <td>Perform single Vault cluster installation per Appendix A and successful completion of VE-INIT-001.
Create two basic policies, in two plain text files:

# Contents of user1.hcl:
path "sys/*" {
  policy = "deny"
}

path "cubbyhole/user1" {
  policy = "write"
}

# Contents of user2.hcl
path "sys/*" {
  policy = "deny"
}

path "cubbyhole/user1" {
  policy = "deny"
}

These policies need to be imported into Vault.

[user@host ~]# vault policy-write user1 user1.hcl
[user@host ~]# vault policy-write user2 user2.hcl

Generate two tokens, associated with the previously created policies:

[user@host ~]# vault token-create -display-name="user1" -policy="user1"
Key            	Value
---            	-----
token          	dcfd673a-8be8-30e3-23fa-5886e016b2c4
token_accessor 	1da226b0-aa5e-261c-f0ea-961b040fadad
token_duration 	768h0m0s
token_renewable	true
token_policies 	[default user1]

[user@host ~]# vault token-create -display-name="user2" -policy="user2"
Key            	Value
---            	-----
token          	07306543-7c7c-8a11-394e-520d8ac6de1f
token_accessor 	825dd333-8f42-0c50-8527-6e01eee4e03d
token_duration 	768h0m0s
token_renewable	true
token_policies 	[default user2]
</td>
  </tr>
  <tr>
    <td>Command/Input</td>
    <td>Using the individual tokens, we’re going to perform a set of actions. In order to identify which user is performing the action, the environment variable will be passed at runtime to the vault binary. 

For simplicity, the actual tokens will be replaced with user-1-aaaa-bbbb and user-2-cccc-dddd in the commands. These strings should be replaced with the actual tokens generated in the system.

Create a secret using the token associated with the user1 policy:

[user@host ~]# VAULT_TOKEN="user-1-aaaa-bbbb" vault write cubbyhole/user1 "password=secret"
Success! Data written to: cubbyhole/user1

Retrieve the secret using the token associated with the user1 policy:

[user@host ~]# VAULT_TOKEN="user1-aaaa-bbbb" vault read cubbyhole/user1
Key     	Value
---     	-----
password	secret

Update the secret using the token associated with the user1 policy:

[user@host ~]# VAULT_TOKEN="user1-aaaa-bbbb" vault write cubbyhole/user1 "password=verysecure"
Success! Data written to: cubbyhole/user1

Retrieve the secret using the token associated with the user1 policy:

[user@host ~]# VAULT_TOKEN="user1-aaaa-bbbb" vault read cubbyhole/user1
Key     	Value
---     	-----
password	verysecure

Attempt to retrieve the secret using the token associated to the user2 policy:

[user@host ~]# VAULT_TOKEN="user2-cccc-dddd" vault read cubbyhole/user1
Error reading cubbyhole/user1: Error making API request.

URL: GET https://127.0.0.1:8200/v1/cubbyhole/user1
Code: 403. Errors:

* permission denied
</td>
  </tr>
  <tr>
    <td>Expected Results</td>
    <td>With the usage of policies, access to secrets can be restricted.
Policies use path based matching to apply rules. A policy may be an  exact match, or might be a glob pattern which uses a prefix. Vault operates in a whitelisting mode, so if a path isn't explicitly allowed, Vault will reject access to it. This works well due to Vault's architecture of being like a filesystem: everything has a path associated with it, including the core configuration mechanism under "sys".
</td>
  </tr>
  <tr>
    <td>Pass (Y/N)</td>
    <td></td>
  </tr>
  <tr>
    <td>Actual Results</td>
    <td></td>
  </tr>
</table>


<table>
  <tr>
    <td>Test Case</td>
    <td>VE-MTEN-005</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Enable different mountpoints to set permissions for multiple tenants in a secure way.</td>
  </tr>
  <tr>
    <td>Setup</td>
    <td>Perform single Vault cluster installation per Appendix A and successful completion of VE-INIT-001.
Create two separate mounts using the generic backend:

vault mount -path=tenant1 generic
vault mount -path=tenant2 generic

Confirm that the new mount points exist using the vault mounts command, output should be similar to the one as follows:

Path        Type       Default TTL  Max TTL  Description
cubbyhole/  cubbyhole  n/a          n/a      
mysql/      mysql      system       system
secret/     generic    system       system   
sys/        system     n/a          n/a      
tenant1/    generic    system       system
tenant2/    generic    system       system
</td>
  </tr>
  <tr>
    <td>Command/Input</td>
    <td>Create three basic policies, in plain text files:

# Contents of tenant1.hcl:
path "sys/*" {
  policy = "deny"
}

path "tenant1/*" {
  policy = "write"
}

# Contents of tenant2.hcl
path "sys/*" {
  policy = "deny"
}

path "tenant2/*" {
  policy = "write"
}

#Contents of tenant1-readonly.hcl
path "tenant1/*" {
  policy = "read"
}

These policies need to be imported into vault:

vault policy-write tenant1 tenant1.hcl
vault policy-write tenant2 tenant2.hcl
vault policy-write tenant1-readonly tenant1-readonly.hcl

At this time, policy creation and token generation is restricted to a Root token.

Generate tokens for the policies:
vault token-create -policy="tenant1" -display-name="tenant1"
vault token-create -policy="tenant2" -display-name="tenant2"
vault token-create -policy="tenant1-readonly" -display-name="tenant1-readonly"
</td>
  </tr>
  <tr>
    <td>Expected Results</td>
    <td>The token associated with tenant1 should have full access to the tenant1 mount point:
[root@vault ~]# VAULT_TOKEN=31e4bd7d-3172-9933-e11c-57bf95ce9f02 vault write tenant1/foo password=secret
Success! Data written to: tenant1/foo
[root@vault ~]# VAULT_TOKEN=31e4bd7d-3172-9933-e11c-57bf95ce9f02 vault read tenant1/foo
Key             	Value
---             	-----
refresh_interval	768h0m0s
password        	secret

The token associated with tenant2 should have full access to the tenant2 mount point, but no access to the tenant1 mount point:

[root@vault ~]# VAULT_TOKEN=8f1336a5-0429-a80c-b370-fcd1ade93940 vault write tenant1/bar password=secret
Error writing data to tenant1/bar: Error making API request.

URL: PUT https://vault.hashicorp.demo:8200/v1/tenant1/bar
Code: 403. Errors:

* permission denied
[root@vault ~]# VAULT_TOKEN=8f1336a5-0429-a80c-b370-fcd1ade93940 vault write tenant2/bar password=secret
Success! Data written to: tenant2/bar
[root@vault ~]#

The token associated with the tenant1-readonly policy should have read only access to the tenant1 mount point, and no access to the tenant 2 mount point:
[root@vault ~]# VAULT_TOKEN=00cd0c7e-4230-ac4a-e68a-cdce779d2b4e vault read tenant1/foo
Key             	Value
---             	-----
refresh_interval	768h0m0s
password        	secret

[root@vault ~]# VAULT_TOKEN=00cd0c7e-4230-ac4a-e68a-cdce779d2b4e vault read tenant2/bar
Error reading tenant2/bar: Error making API request.

URL: GET https://vault.hashicorp.demo:8200/v1/tenant2/bar
Code: 403. Errors:

* permission denied
[root@vault ~]# VAULT_TOKEN=00cd0c7e-4230-ac4a-e68a-cdce779d2b4e vault write tenant1/baz foo=bar
Error writing data to tenant1/baz: Error making API request.

URL: PUT https://vault.hashicorp.demo:8200/v1/tenant1/baz
Code: 403. Errors:

* permission denied
</td>
  </tr>
  <tr>
    <td>Pass (Y/N)</td>
    <td></td>
  </tr>
  <tr>
    <td>Actual Results</td>
    <td></td>
  </tr>
</table>


<table>
  <tr>
    <td>Test Case</td>
    <td>VE-DYN-006</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Configure Vault to provide dynamic credentials.</td>
  </tr>
  <tr>
    <td>Setup</td>
    <td>In order to evaluate the following set of capabilities, a persistent backend is required. Secrets will be created to access this backend and consumed by different applications or alternative agent based solutions such as consul-template or envconsul.
For evaluation purposes, the example below assumes a MySQL backend will be used. Other supported backends include, but are not limited to:
AWS
Cassandra
MongoDB
Microsoft SQL Server
PKI (for SSL Certificates)
PostgreSQL
RabbitMQ
SSH Authentication

There should be a user created in MySQL that allows Vault Enterprise to generate credentials:

CREATE USER 'vaultuser'@'%' IDENTIFIED BY PASSWORD '*HASH';
GRANT ALL PRIVILEGES ON *.* TO 'vaultuser'@'%' WITH GRANT OPTION;


Mount the secret backend into Vault:

vault mount mysql

Configure the mysql credentials in the secret backend:

vault write mysql/config/connection connection_url="vaultuser:mysqlpassword@tcp(mysql.server.fqdn:3306)/" 

Configure the lease for the credentials:
vault write mysql/config/lease lease=5m lease_max=24h

This command would create leases that last for 5 minutes.

Configure a role for the credentials. A role would specify the permissions that the generated credentials would get in MySQL:

vault write mysql/roles/readonly sql="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';"

The aforementioned command would create a user that has read permissions to every database and every table.</td>
  </tr>
  <tr>
    <td>Command/Input</td>
    <td>Request credentials from vault using the read command:
vault read mysql/creds/readonly

Verify the creation of credentials in MySQL using the following command:
select user from mysql.user;

Revoke a specific set of credentials using the vault revoke command:
vault revoke mysql/creds/readonly/b947cc33-5efc-1af9-7d4b-1cbb4befd688

Or as an emergency procedure, revoke all credentials created for a specific role using the prefix option:
vault revoke -prefix=true mysql/creds/readonly</td>
  </tr>
  <tr>
    <td>Expected Results
</td>
    <td>Upon requesting a set of credentials:
[root@vault ~]# vault read mysql/creds/readonly
Key            	Value
---            	-----
lease_id       	mysql/creds/readonly/b947cc33-5efc-1af9-7d4b-1cbb4befd688
lease_duration 	5m0s
lease_renewable	true
password       	3da9ca70-eda2-ded1-9274-dc8f3fbcb4f1
username       	read-root-1bcc17

The specified username should show among the MySQL users:

MariaDB [(none)]> select user from mysql.user;
+------------------+
| user             |
+------------------+
| read-root-1bcc17 |
| vault            |
| root             |
| root             |
|                  |
| root             |
|                  |
| root             |
+------------------+

Upon revoking the secret, or once the lease time has elapsed, the user must disappear from the MySQL user table.
[root@vault ~]# vault revoke mysql/creds/readonly/b947cc33-5efc-1af9-7d4b-1cbb4befd688
Success! Revoked the secret with ID 'mysql/creds/readonly/b947cc33-5efc-1af9-7d4b-1cbb4befd688', if it existed.
</td>
  </tr>
  <tr>
    <td>Pass (Y/N)</td>
    <td></td>
  </tr>
</table>


<table>
  <tr>
    <td>Test Case</td>
    <td>VE-TEMP-007</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Use agent based strategies to generate configuration file templates, in order for applications to consume secrets.</td>
  </tr>
  <tr>
    <td>Setup</td>
    <td>Perform single Vault cluster installation per Appendix A and successful completion of VE-INIT-001. Enable the MySQL Secrets backend as described in VE-DYN-006.

Two agent based strategies will be evaluated, using envconsul and consul-template. Envconsul would provision environment variables consuming secrets from Vault Enterprise, while consul-template would render configuration files based from templates, consuming secrets dynamically from Vault Enterprise.

Binaries for the latest versions of these agents (as of the time of authoring this document) can be obtained respectively from:
https://releases.hashicorp.com/envconsul/0.6.2/
https://releases.hashicorp.com/consul-template/0.18.1/

In Vault, a policy needs to be generated allowing tokens to read credentials:

#Contents of mysql-readonly.hcl
path "mysql/creds/readonly" {
  policy = "read"
}

vault policy-write mysql-readonly mysql-readonly.hcl

A token needs to be generated using the aforementioned policy:
vault token-create -display-name='application1' -policy='mysql-readonly'

Example configuration for envconsul or consul-template:

#Contents of config.hcl
vault {
  address = "https://vault.hashicorp.demo:8200"
  token   = "6cbf8b0d-49ff-761c-98c2-6f4151be024b" // May also be specified via the envvar VAULT_TOKEN
  renew   = true

  ssl {
    enabled = true
    verify  = false
  }
}

An example template for an ini-style configuration template could be as follows:

#Contents of mysql.ini.ctmpl
[mysql]
{{ with $secret := secret "mysql/creds/readonly" }}
username={{$secret.Data.username}}
password={{$secret.Data.password}}
{{ end }}
</td>
  </tr>
  <tr>
    <td>Command/Input</td>
    <td>From the target system, running the following command to verify how envconsul sets environment variables:

envconsul -config=./config.hcl -secret=mysql/creds/readonly env
Where env command in this case is just used to display environment variables.

Alternatively, a template can be rendered to consume the secrets:
consul-template -config=./config.hcl -template="./mysql.ini.ctmpl:./mysql.ini"</td>
  </tr>
  <tr>
    <td>Expected Results</td>
    <td>The filtered output from the envconsul command setting environment variables should render a result similar to the one that follows:

envconsul -config=./config.hcl -secret=mysql/creds/readonly env | grep mysql
2017/02/13 00:59:41 [WARN] (clients) disabling vault SSL verification
2017/02/13 00:59:41 looking at vault mysql/creds/readonly
mysql_creds_readonly_username=read-toke-0b0c95
mysql_creds_readonly_password=6651ddde-3062-ebf2-8977-07ecbbb76c0c

While rendering a template should provide a file with the right secrets:
consul-template -config=./config.hcl -template="./mysql.ini.ctmpl:./mysql.ini"
[root@database ~]# cat mysql.ini
[mysql]

username=read-toke-a0dd76
password=0044ec8c-0ea1-5b9c-14b8-07298928ece9

These patterns are great for integration with configuration management tools such as Chef, Saltstack or Puppet, simply configuring the services.
</td>
  </tr>
  <tr>
    <td>Pass (Y/N)</td>
    <td></td>
  </tr>
  <tr>
    <td>Actual Results</td>
    <td></td>
  </tr>
</table>


<table>
  <tr>
    <td>Test Case</td>
    <td>VE-AUTH-008</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Use an LDAP Directory as authentication backend. Enable MFA using Duo.</td>
  </tr>
  <tr>
    <td>Setup</td>
    <td>Given a simple directory, with the following structure:


Set up LDAP Authentication in Vault:

vault write auth/ldap/config     url="ldap://directory.hashicorp.demo"     groupdn="ou=Group,dc=example,dc=com"    starttls=false     binddn="cn=Manager,dc=example,dc=com"     bindpass='hashicorp' userattr="uid" userdn="ou=People,dc=example,dc=com" 

And assign policies to the existing groups:
[root@vault ~]# vault write auth/ldap/groups/sales policies=tenant2
Success! Data written to: auth/ldap/groups/sales
[root@vault ~]# vault write auth/ldap/groups/engineering policies=tenant1
Success! Data written to: auth/ldap/groups/engineering
Check policies using vault read and list:
[root@vault ~]# vault read auth/ldap/groups/sales
Key     	Value
---     	-----
policies	default,tenant2

[root@vault ~]# vault list auth/ldap/groups
Keys
----
engineering
sales

Alternatively, configure Duo for Multifactor authentication:

vault write auth/ldap/mfa_config type=duo
vault write auth/ldap/duo/access \    host=[host] \    ikey=[integration key] \    skey=[secret key]
</td>
  </tr>
  <tr>
    <td>Command/Input</td>
    <td>Login using
[root@vault ~]# vault auth -method=ldap username=directoryusername

If MFA is enabled, you’ll require to either provide a one time password or accept a Duo Push
</td>
  </tr>
  <tr>
    <td>Expected Results
</td>
    <td>The command should return an output similar to the one below:
[root@vault ~]# vault auth -method=ldap username=nico
==> WARNING: VAULT_TOKEN environment variable set!

  The environment variable takes precedence over the value
  set by the auth command. Either update the value of the
  environment variable or unset it to use the new token.

Password (will be hidden):
Successfully authenticated! You are now logged in.
The token below is already saved in the session. You do not
need to "vault auth" again with the token.
token: 55496d13-3f75-78da-37ae-173338acd44c
token_duration: 0
token_policies: [default tenant1]

</td>
  </tr>
  <tr>
    <td>Pass (Y/N)</td>
    <td></td>
  </tr>
</table>

