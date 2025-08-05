locals {
  ignore_keys_in_organization_structure_validation = [
    var.cascading_tags_key,
    var.static_tags_key
  ]
}

variable "cascading_tags_key" {
  description = "A key that will be ignored within organization_structure, and will instead be used to define a map of tags for the OU. These tags will cascade to child OUs if the same key isn't defined on a nested OU."
  type        = string
  default     = ""
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

variable "name_path_delimiter" {
  description = "Delimiter used to join names in the name_path attribute of each OU."
  type        = string
  default     = "/"
}

variable "organization_structure" {
  description = "The structure of OUs to manage as a map of maps."
  type        = any

  validation {
    # var.name_path_delimiter may be used in the tag keys/values
    condition = alltrue(concat(
      # Level 1
      [for l1_k in keys(var.organization_structure) :
      !strcontains(l1_k, var.name_path_delimiter) || contains(local.ignore_keys_in_organization_structure_validation, l1_k)],
      # Level 2
      flatten([for l1_k, l1_v in var.organization_structure : [
        for l2_k in try(keys(l1_v), []) :
        !strcontains(l2_k, var.name_path_delimiter) || contains(local.ignore_keys_in_organization_structure_validation, l2_k)
      ] if !contains(local.ignore_keys_in_organization_structure_validation, l1_k)]),
      # Level 3
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) : [
          for l3_k in try(keys(l2_v), []) :
          !strcontains(l3_k, var.name_path_delimiter) || contains(local.ignore_keys_in_organization_structure_validation, l3_k)
        ] if !contains(local.ignore_keys_in_organization_structure_validation, l2_k)])
      if !contains(local.ignore_keys_in_organization_structure_validation, l1_k)]),
      # Level 4
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          flatten([for l3_k, l3_v in try(l2_v, {}) : [
            for l4_k in try(keys(l3_v), []) :
            !strcontains(l4_k, var.name_path_delimiter) || contains(local.ignore_keys_in_organization_structure_validation, l4_k)
          ] if !contains(local.ignore_keys_in_organization_structure_validation, l3_k)])
        if !contains(local.ignore_keys_in_organization_structure_validation, l2_k)])
      if !contains(local.ignore_keys_in_organization_structure_validation, l1_k)]),
      # Level 5
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          flatten([for l3_k, l3_v in try(l2_v, {}) :
            flatten([for l4_k, l4_v in try(l3_v, {}) : [
              for l5_k in try(keys(l4_v), []) :
              !strcontains(l5_k, var.name_path_delimiter) || contains(local.ignore_keys_in_organization_structure_validation, l5_k)
            ] if !contains(local.ignore_keys_in_organization_structure_validation, l4_k)])
          if !contains(local.ignore_keys_in_organization_structure_validation, l3_k)])
        if !contains(local.ignore_keys_in_organization_structure_validation, l2_k)])
      if !contains(local.ignore_keys_in_organization_structure_validation, l1_k)])
    ))
    error_message = "OU names cannot contain the name_path_delimiter (${var.name_path_delimiter}), except within ${var.cascading_tags_key} or ${var.static_tags_key} properties."
  }
  validation {
    # ":::" may be used in the tag keys/values
    condition = alltrue(concat(
      # Level 1
      [for l1_k in keys(var.organization_structure) :
      !strcontains(l1_k, ":::") || contains(local.ignore_keys_in_organization_structure_validation, l1_k)],
      # Level 2
      flatten([for l1_k, l1_v in var.organization_structure : [
        for l2_k in try(keys(l1_v), []) :
        !strcontains(l2_k, ":::") || contains(local.ignore_keys_in_organization_structure_validation, l2_k)
      ] if !contains(local.ignore_keys_in_organization_structure_validation, l1_k)]),
      # Level 3
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) : [
          for l3_k in try(keys(l2_v), []) :
          !strcontains(l3_k, ":::") || contains(local.ignore_keys_in_organization_structure_validation, l3_k)
        ] if !contains(local.ignore_keys_in_organization_structure_validation, l2_k)])
      if !contains(local.ignore_keys_in_organization_structure_validation, l1_k)]),
      # Level 4
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          flatten([for l3_k, l3_v in try(l2_v, {}) : [
            for l4_k in try(keys(l3_v), []) :
            !strcontains(l4_k, ":::") || contains(local.ignore_keys_in_organization_structure_validation, l4_k)
          ] if !contains(local.ignore_keys_in_organization_structure_validation, l3_k)])
        if !contains(local.ignore_keys_in_organization_structure_validation, l2_k)])
      if !contains(local.ignore_keys_in_organization_structure_validation, l1_k)]),
      # Level 5
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          flatten([for l3_k, l3_v in try(l2_v, {}) :
            flatten([for l4_k, l4_v in try(l3_v, {}) : [
              for l5_k in try(keys(l4_v), []) :
              !strcontains(l5_k, ":::") || contains(local.ignore_keys_in_organization_structure_validation, l5_k)
            ] if !contains(local.ignore_keys_in_organization_structure_validation, l4_k)])
          if !contains(local.ignore_keys_in_organization_structure_validation, l3_k)])
        if !contains(local.ignore_keys_in_organization_structure_validation, l2_k)])
      if !contains(local.ignore_keys_in_organization_structure_validation, l1_k)])
    ))
    error_message = "OU names cannot contain \":::\" as this is used within the module to separate levels."
  }
  validation {
    condition     = alltrue([for l1_k in keys(var.organization_structure) : l1_k != var.static_tags_key])
    error_message = "Static tags cannot be added to the Organization Root through Terraform."
  }
}

variable "static_tags_key" {
  description = "A key that will be ignored within organization_structure, and will instead be used to define a map of tags on the OU."
  type        = string
  default     = ""
}
