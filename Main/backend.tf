terraform {
  backend "s3" {
    bucket  = "my-three-tier-architeture-app-project123"
    encrypt = true
    key     = "terraform.tfstate"
    region  = "us-east-1"
  }
}