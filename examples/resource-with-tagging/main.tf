module "ous" {
  source = "../../"
  # source  = "nationalarchives/organizations-ous-by-path/aws"
  # version = "1.1.0"

  name_path_delimiter    = " / "
  organization_structure = local.org_structure

  # These can be customised if required
  # static_tags_key    = "@tags"
  # cascading_tags_key = "Vtags"
}
