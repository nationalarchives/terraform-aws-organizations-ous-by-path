# terraform-aws-organizations-ous-by-path

A Terraform module to expose AWS Organizations Organizational Units with their relative paths from the Organization root.

Each OU is represented as a Map with attributes.

| Name | Description | Example |
|------|-------------|---------|
| arn | The ARN of the OU. | `arn:aws:organizations::111111111111:ou/o-zyxsjdkdu5/ou-1abc-abcdefg` |
| id | The id of the OU. | `ou-1abc-abcdefg` |
|id_path | The path to the OU from the Organization ID, to be used with the `aws:PrincipalOrgPaths` and `aws:ResourceOrgPaths` conditions. | `o-zyxsjdkdu5/r-1abc/ou-1abc-bzfjwfg8/ou-1abc-abcdefg/` |
| name | The name of the OU. | `Level 2 OU` |
| name_path | The name of all OUs in the path to the OU, delimited by the input `name_path_delimiter`. | `Level 1 OU/Level 2 OU` |
| parent_id | The id of the OU's direct parent. | `ou-1abc-bzfjwfg8` |

## Usage

```hcl
module "ous" {
  source = "kurtismash/organizations-ous-by-path/aws"
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
      values   = [module.ous.by_name_path["Level 1 OU/Level 2 OU"].id_path]
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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.43.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_path_delimiter"></a> [name\_path\_delimiter](#input\_name\_path\_delimiter) | Delimiter used to join names in the name\_path attribute of each OU. | `string` | `"/"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_by_id"></a> [by\_id](#output\_by\_id) | Map of all OUs indexed by id. |
| <a name="output_by_name_path"></a> [by\_name\_path](#output\_by\_name\_path) | Map of all OUs indexed by name\_path. |
| <a name="output_list"></a> [list](#output\_list) | List of all OUs with added attributes id\_path and name\_path. |
