variable "project" {
  description = "Préfixe des noms de ressources"
  type        = string
}

variable "environment" {
  description = "Nom de l'environnement (dev, staging, prod)"
  type        = string
}

variable "queue_retention_seconds" {
  description = "Durée de conservation des messages SQS"
  type        = number
  default     = 345600
}

variable "versioning" {
  description = "Active le versioning du bucket S3"
  type        = bool
  default     = false
}
