include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/app-infra"
}

inputs = {
  project                 = "portfolio-tg"
  environment             = "staging"
  queue_retention_seconds = 345600
  versioning              = false
}
