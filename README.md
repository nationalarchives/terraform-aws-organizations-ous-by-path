# Terraform module: AWS Organizations OUs by path

> :warning: **NOTICE:** This module has moved to the `nationalarchives` GitHub organization, please update your source accordingly. The module is now available at [nationalarchives/terraform-aws-organizations-ous-by-path](https://github.com/nationalarchives/terraform-aws-organizations-ous-by-path).

A Terraform module to create and/or expose AWS Organizations Organizational Units with their paths from the Organization root.

- Can be used as a **resource** or **data source** with the same outputs.
- Supports up to **5 levels** of Organizational Units (AWS Quota).
- Define your organization structure as a map.
- Generates OrgPaths, to be used with the `aws:PrincipalOrgPaths` and `aws:ResourceOrgPaths` IAM conditions.
- Organizational Units are exposed via a list and indexed maps, see <a name="Outputs"></a> [Outputs](#Outputs) for more information.

<br/>
Each OU is represented as a map with attributes

- `arn` - ARN of the OU.
- `child_accounts` - List of AWS accounts that are direct children of the OU. Dependent upon the `include_child_accounts` variable.
  - `arn` - ARN of the account.
  - `email` - Email of the account.
  - `id` - Identifier of the account.
  - `name` - Name of the account.
- `descendant_accounts` - List of AWS accounts that are direct children or descendants of the OU. Dependent upon the `include_descendant_accounts` variable.
  - `arn` - ARN of the account.
  - `email` - Email of the account.
  - `id` - Identifier of the account.
  - `name` - Name of the account.
- `id` - ID of the OU.
- `name` - Name of the OU.
- `name_path` - Path to the OU using OU names, delimited by the `name_path_delimiter` variable.
- `org_path` - Path to the OU from the Organization ID, to be used with the `aws:PrincipalOrgPaths` and `aws:ResourceOrgPaths` IAM conditions.
- `parent_id` - ID of the OU's direct parent.

## Usage

### As a resource

```hcl
module "ous" {
  source = "kurtismash/organizations-ous-by-path/aws"
  # It's recommended to explicitly constrain the acceptable version numbers to avoid unexpected or unwanted changes.

  organization_structure = {
    "Level 1 OU" = {
      "Level 2 OU" = {
        "Level 3 OU" = {
          "Level 4 OU" = {
            "Level 5 OU"   = {},
            "Level 5 OU-2" = {}
          }
        }
      }
    },
    "Level 1 OU-2" = {}
  }
}

data "aws_iam_policy_document" "scp" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }
}
resource "aws_organizations_policy" "scp" {
  name    = "SCP"
  content = data.aws_iam_policy_document.scp.json
}
resource "aws_organizations_policy_attachment" "scp" {
  policy_id = aws_organizations_policy.scp.id
  target_id = module.ous.by_name_path["Level 1 OU/Level 2 OU/Level 3 OU"].id
}
```

### As a data source

```hcl
module "ous" {
  source = "kurtismash/organizations-ous-by-path/aws"
  # It's recommended to explicitly constrain the acceptable version numbers to avoid unexpected or unwanted changes.
}

# Create a bucket and allow access from accounts within a specified OU.
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:PrincipalOrgPaths"
      values   = [module.ous.by_name_path["Level 1 OU/Level 2 OU"].org_path]
    }
  }
}
resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "bucket-"
}
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.10.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.55.0 |

## Providers

No providers.

## Modules

| Name                                                        | Source             | Version |
| ----------------------------------------------------------- | ------------------ | ------- |
| <a name="module_data"></a> [data](#module_data)             | ./modules/data     | n/a     |
| <a name="module_resource"></a> [resource](#module_resource) | ./modules/resource | n/a     |

## Resources

No resources.

## Inputs

| Name                                                                                                               | Description                                                                                                   | Type     | Default | Required |
| ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- | -------- | ------- | :------: |
| <a name="input_include_child_accounts"></a> [include_child_accounts](#input_include_child_accounts)                | Include direct child AWS accounts in the output, increases the number of API calls when enabled.              | `bool`   | `false` |    no    |
| <a name="input_include_descendant_accounts"></a> [include_descendant_accounts](#input_include_descendant_accounts) | Include descendant AWS accounts in the output, increases complexity when enabled.                             | `bool`   | `false` |    no    |
| <a name="input_name_path_delimiter"></a> [name_path_delimiter](#input_name_path_delimiter)                         | Delimiter used to join names in the name_path attribute of each OU.                                           | `string` | `"/"`   |    no    |
| <a name="input_organization_structure"></a> [organization_structure](#input_organization_structure)                | The structure of OUs to manage as a map of maps. If not provided, this module will function as a data source. | `any`    | `{}`    |    no    |

## Outputs

| Name                                                                    | Description                                               |
| ----------------------------------------------------------------------- | --------------------------------------------------------- |
| <a name="output_by_id"></a> [by_id](#output_by_id)                      | Map of OUs indexed by id.                                 |
| <a name="output_by_name_path"></a> [by_name_path](#output_by_name_path) | Map of OUs indexed by name_path.                          |
| <a name="output_list"></a> [list](#output_list)                         | List of OUs with added attributes name_path and org_path. |

<!-- END_TF_DOCS -->
