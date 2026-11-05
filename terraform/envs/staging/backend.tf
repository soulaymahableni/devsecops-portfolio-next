terraform {
  backend "s3" {
    key = "staging/terraform.tfstate"
  }
}
