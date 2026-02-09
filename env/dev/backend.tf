terraform {
  backend "s3" {
    bucket         = "ktcloud-tfstate-762233736868-apne2"
    key            = "env/dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "ktcloud-terraform-lock"
    encrypt        = true
  }
}

