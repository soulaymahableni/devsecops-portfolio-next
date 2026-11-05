variable "region" {
  description = "Région AWS (fictive avec Floci)"
  type        = string
  default     = "us-east-1"
}

variable "endpoint" {
  description = "Adresse de Floci"
  type        = string
  default     = "http://localhost:4566"
}

variable "access_key" {
  description = "Identifiant fictif pour Floci"
  type        = string
  default     = "test"
}

variable "secret_key" {
  description = "Secret fictif pour Floci"
  type        = string
  default     = "test"
}

variable "project" {
  description = "Préfixe des noms de ressources"
  type        = string
  default     = "portfolio-tf"
}
