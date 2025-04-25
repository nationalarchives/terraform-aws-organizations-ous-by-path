variable "include_aws_accounts" {
  description = "Include AWS accounts in the output, increases the number of API calls when enabled."
  type        = bool
}

variable "name_path_delimiter" {
  description = "Delimiter used to join names in the name_path attribute of each OU."
  type        = string
}

variable "ou_name_paths" {
  description = "A list of OU paths for the OUs to create at the current level."
  type        = list(string)
}

variable "parent_level_ou_map" {
  description = "output.list from the previous level of OUs."
  type = map(object({
    id        = string
    id_path   = string
    name_path = string
  }))
}
