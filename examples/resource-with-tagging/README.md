# AWS Organizations OU by Path

Creates Organization Units with tags within an AWS Organization. To be deployed to the management account within an existing AWS Organization.

## Local Development - Terraform

from within this subdirectory:

```
terraform init -backend-config=bucket={YOUR_TERRAFORM_STATE_BUCKET} -backend-config=key=organization-ous -backend-config=region={YOUR_TERRAFORM_STATE_REGION}
terraform plan
terraform apply
```
