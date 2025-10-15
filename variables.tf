variable "cascading_tags_key" {
  description = "A key that will be ignored within organization_structure, and will instead be used to define a map of tags for the OU. These tags will cascade to child OUs if the same key isn't defined on a nested OU."
  type        = string
  default     = "Vtags"
}

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

variable "include_ou_tags" {
  description = "Include tags for each OU in the output, increases the number of API calls when enabled. Has no effect when organization_structure is provided."
  type        = bool
  default     = false
}

variable "name_path_delimiter" {
  description = "Delimiter used to join names in the name_path attribute of each OU."
  type        = string
  default     = "/"
}

variable "organization_structure" {
  description = "The structure of OUs to manage as a map of maps. If not provided, this module will function as a data source."
  type        = any
  default     = {}
}

variable "static_tags_key" {
  description = "A key that will be ignored within organization_structure, and will instead be used to define a map of tags on the OU."
  type        = string
  default     = "@tags"
}
