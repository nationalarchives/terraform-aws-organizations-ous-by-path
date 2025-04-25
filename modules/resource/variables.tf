variable "include_child_accounts" {
  description = "Include direct child AWS accounts in the output, increases the number of API calls when enabled."
  type        = bool
  default     = false
}

variable "include_descendant_accounts" {
  description = "Include descendant AWS accounts in the output, increases complexity when enabled."
  type        = bool
  default     = false

  validation {
    condition     = alltrue([var.include_child_accounts, var.include_descendant_accounts]) || !var.include_descendant_accounts
    error_message = "You cannot include descendant accounts without child accounts."
  }
}

variable "name_path_delimiter" {
  description = "Delimiter used to join names in the name_path attribute of each OU."
  type        = string
  default     = "/"
}

variable "organization_structure" {
  description = "The structure of OUs to manage as a map of maps."
  type        = any

  validation {
    condition     = !strcontains(jsonencode(var.organization_structure), var.name_path_delimiter)
    error_message = "OU names cannot contain the name_path_delimiter."
  }
  validation {
    condition     = !strcontains(jsonencode(var.organization_structure), local.internal_name_path_delimiter)
    error_message = "OU names cannot contain \"${local.internal_name_path_delimiter}\" as this is used within the module to separate levels."
  }
}
