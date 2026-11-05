include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/app-infra"
}

inputs = {
  project                 = "portfolio-tg"
  environment             = "prod"
  queue_retention_seconds = 1209600
  versioning              = true
}
