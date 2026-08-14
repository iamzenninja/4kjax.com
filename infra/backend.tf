terraform {
  backend "s3" {
    bucket = "4kjax-terraform-state"
    key = "prod/website/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "4kjax-terraform-locks"
    encrypt = true
  }
}