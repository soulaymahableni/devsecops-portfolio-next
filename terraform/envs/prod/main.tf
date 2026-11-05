module "app" {
  source                  = "../../modules/app-infra"
  project                 = var.project
  environment             = "prod"
  queue_retention_seconds = 1209600
  versioning              = true
}
