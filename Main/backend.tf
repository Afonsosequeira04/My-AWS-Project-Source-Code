terraform {
  backend "s3" {
    bucket  = "my-three-tier-app-project1"
    encrypt = true
    key     = "terraform.tfstate"
    region  = "us-east-1"
  }
}