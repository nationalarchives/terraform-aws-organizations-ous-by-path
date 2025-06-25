# Terraform module: AWS Organizations OUs by path - Resource sub-module

A Terraform module to **manage** AWS Organizations Organizational Units with their paths from the Organization root.

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
- `org_path` - Path to the OU from the Organization ID, to be used with the `aws:PrincipalOrgPaths` and `aws:ResourceOrgPaths` conditions.
- `parent_id` - ID of the OU's direct parent.

## Usage

```hcl
module "ous" {
  source = "kurtismash/organizations-ous-by-path/aws//modules/resource"
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

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.10.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.55.0 |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.96.0  |

## Modules

| Name                                      | Source             | Version |
| ----------------------------------------- | ------------------ | ------- |
| <a name="module_l1"></a> [l1](#module_l1) | ./modules/ou_level | n/a     |
| <a name="module_l2"></a> [l2](#module_l2) | ./modules/ou_level | n/a     |
| <a name="module_l3"></a> [l3](#module_l3) | ./modules/ou_level | n/a     |
| <a name="module_l4"></a> [l4](#module_l4) | ./modules/ou_level | n/a     |
| <a name="module_l5"></a> [l5](#module_l5) | ./modules/ou_level | n/a     |

## Resources

| Name                                                                                                                                            | Type        |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name                                                                                                               | Description                                                                                      | Type     | Default | Required |
| ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ | -------- | ------- | :------: |
| <a name="input_include_child_accounts"></a> [include_child_accounts](#input_include_child_accounts)                | Include direct child AWS accounts in the output, increases the number of API calls when enabled. | `bool`   | `false` |    no    |
| <a name="input_include_descendant_accounts"></a> [include_descendant_accounts](#input_include_descendant_accounts) | Include descendant AWS accounts in the output, increases complexity when enabled.                | `bool`   | `false` |    no    |
| <a name="input_name_path_delimiter"></a> [name_path_delimiter](#input_name_path_delimiter)                         | Delimiter used to join names in the name_path attribute of each OU.                              | `string` | `"/"`   |    no    |
| <a name="input_organization_structure"></a> [organization_structure](#input_organization_structure)                | The structure of OUs to manage as a map of maps.                                                 | `any`    | n/a     |   yes    |

## Outputs

| Name                                                                    | Description                                                       |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------- |
| <a name="output_by_id"></a> [by_id](#output_by_id)                      | Map of managed OUs indexed by id.                                 |
| <a name="output_by_name_path"></a> [by_name_path](#output_by_name_path) | Map of managed OUs indexed by name_path.                          |
| <a name="output_list"></a> [list](#output_list)                         | List of managed OUs with added attributes name_path and org_path. |

<!-- END_TF_DOCS -->
