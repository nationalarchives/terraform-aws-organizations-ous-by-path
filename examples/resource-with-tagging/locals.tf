locals {
  org_structure = {
    "Backup" = {},
    "Security" = {
      "Forensics"        = {},
      "Logging"          = {},
      "Security Tooling" = {}
    },
    "Suspended" = {},
    "Workloads" = {
      "Application" = {
        "Development" = {},
        "Staging"     = {},
        "Production"  = {},
        "@tags" = {
          "Project" = "Application" # Sets Project=Application on this OU only
        },
        "Vtags" = {
          "CostCode" = "838" # Overrides the 999 value from parent OU for this and all child OUs
        }
      },
      "Serverless" = {
        "CA" = {
          "Cloud CA" = {},
          "ECDSA CA" = {},
          "RSA CA"   = {},
          "@tags" = {
            "Project"  = "Serverless CA" # Sets Project="Serverless CA" on this OU only
            "CostCode" = "173"           # Overrides the 999 value from parent OU on this OU only (child OUs are unaffected)
          }
        },
        "Cloud Apps" = {}
      },
      "Vtags" = {
        "CostCode" = "999" # CostCode=999 will be applied to Workloads and all child OUs, unless a more specific CostCode tag is applied
      }
    }
  }
}
