include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/app-infra"
}

inputs = {
  project                 = "portfolio-tg"
  environment             = "dev"
  queue_retention_seconds = 86400
  versioning              = false
}
