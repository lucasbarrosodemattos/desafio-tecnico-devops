locals {
  project_name = "sensedia-devops"
  aws_region   = get_env("AWS_REGION", "us-east-1")

  state_bucket_name = get_env(
    "TF_STATE_BUCKET",
    "lucasbarrosodemattos-sensedia-devops-tfstate"
  )

  state_lock_table_name = get_env(
    "TF_STATE_LOCK_TABLE",
    "lucasbarrosodemattos-sensedia-devops-tflocks"
  )
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = local.state_bucket_name
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = local.state_lock_table_name

    skip_bucket_versioning         = false
    skip_bucket_ssencryption       = false
    bucket_sse_algorithm           = "AES256"
    enable_lock_table_ssencryption = true

    s3_bucket_tags = {
      Project   = local.project_name
      ManagedBy = "Terragrunt"
      Purpose   = "Terraform remote state"
    }

    dynamodb_table_tags = {
      Project   = local.project_name
      ManagedBy = "Terragrunt"
      Purpose   = "Terraform state locking"
    }
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
  provider "aws" {
    region = "${local.aws_region}"

    default_tags {
      tags = {
        Project   = "${local.project_name}"
        ManagedBy = "Terraform"
      }
    }
  }
  EOF
}