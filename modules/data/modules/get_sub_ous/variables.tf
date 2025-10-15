variable "include_aws_accounts" {
  description = "Include AWS accounts in the output, increases the number of API calls when enabled."
  type        = bool
}

variable "include_ou_tags" {
  description = "Include tags for each OU in the output, increases the number of API calls when enabled."
  type        = bool
}

variable "name_path_delimiter" {
  description = "Delimiter used to join names in the name_path attribute of each OU."
  type        = string
}

variable "parent_level_ou_list" {
  description = "output.list from the previous level of OUs."
  type = list(object({
    id        = string
    name_path = string
    org_path  = string
  }))
}

