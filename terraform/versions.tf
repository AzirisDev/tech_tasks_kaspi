terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3 (Task 6.5). Fill in your bucket/table and run:
  #   terraform init
  # The bucket and DynamoDB lock table must exist beforehand.
  backend "s3" {
    bucket         = "devops-test-tfstate-CHANGE-ME"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-test-tf-lock"
    encrypt        = true
  }
}
