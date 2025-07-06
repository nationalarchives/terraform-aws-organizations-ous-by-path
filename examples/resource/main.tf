module "ous" {
  source = "../../"
  # source  = "nationalarchives/organizations-ous-by-path/aws"
  # version = "1.0.0"

  name_path_delimiter = " / "

  organization_structure = {
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
        "Production"  = {}
      },
      "Serverless" = {
        "CA" = {
          "Cloud CA" = {},
          "ECDSA CA" = {},
          "RSA CA" = {}
        },
        "Cloud Apps" = {}
      }
    }
  }
}