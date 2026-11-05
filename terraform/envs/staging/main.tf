module "app" {
  source                  = "../../modules/app-infra"
  project                 = var.project
  environment             = "staging"
  queue_retention_seconds = 345600
  versioning              = false
}
