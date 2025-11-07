# Remote state backend (optional).
# Uncomment + fill if you want to use S3 & DynamoDB for locking.
#
# terraform {
#   backend "s3" {
#     bucket         = "my-tf-state-bucket"
#     key            = "aws-infra/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "tf-locks"
#     encrypt        = true
#   }
# }
