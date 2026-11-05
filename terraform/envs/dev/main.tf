module "app" {
  source                  = "../../modules/app-infra"
  project                 = var.project
  environment             = "dev"
  queue_retention_seconds = 86400
  versioning              = false
}
