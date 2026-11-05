module "app" {
  source                  = "../../modules/app-infra"
  project                 = var.project
  environment             = "tofu"
  queue_retention_seconds = 86400
  versioning              = false
}
