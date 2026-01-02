provider "aws" {
  default_tags {
    tags = {
      Appli          = var.project_name
      Component      = local.domain_name
      Env            = terraform.workspace
      git_repository = var.git_repository
    }
  }
}

terraform {
  backend "s3" {
    key                  = "network_platform.tfstate"
    workspace_key_prefix = ""
    encrypt              = true
    region               = "eu-west-1"
    dynamodb_table       = "poc_terraform_backend"
  }
}
