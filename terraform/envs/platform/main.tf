# Infrastructure de la plateforme déployée par automation/rebuild.sh (Q134)
module "app" {
  source                  = "../../modules/app-infra"
  project                 = var.project
  environment             = "platform"
  queue_retention_seconds = 345600
  versioning              = true
}
