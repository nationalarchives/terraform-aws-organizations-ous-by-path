module "ous" {
  source = "../../"
  # source  = "nationalarchives/organizations-ous-by-path/aws"
  # version = "1.0.0"

  name_path_delimiter = " / "
  include_ou_tags     = true
}