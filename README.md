## Enablement Lab
This is a tool for SEs to run enablement workshops (at this time, only for Vault).
When doing a Vault session, it provisions a single Consul instance (for Storage Backend, with all services registered on it), a Directory and a Database (mysql only at this time, PostgreSQL in the future).

### Getting started
Clone this repo, and configure the following variables (probably on terraform.tfvars)
- awsaccountid
- namespace: A unique ID for the lab
- students: List of people assisting to the lab, will be used for usernames on the instances for login, and for the storage path in Consul for each Vault cluster (Example: ["ncorrare","bgreen"])
Drop the vault.zip enterprise Binary on modules/students/files/, it's copied, installed and set up automatically.

Once it's done, the environment variables are set up automatically for each user, just try a vault init and go from there.

The AWS provider is configured to read the default credentials for a file. Right now is on main/aws.tf, but it will be turned into a variable in the future.

From the main directory, 'terraform apply'

A key is deployed to login into each ec2-user, but each student can login using his username and 'hashicorp' as password. There is also a guide with a set of exercises you can run in this lab for enablement.

