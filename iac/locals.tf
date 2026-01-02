locals {
  stage_name       = terraform.workspace
  domain_name      = "network_platform"
  environment_name = "${var.project_name}_${local.domain_name}_${local.stage_name}"
  tags_map = {
    Appli          = var.project_name
    Component      = local.domain_name
    Env            = local.stage_name
    git_repository = var.git_repository
    git_branch     = var.git_branch
  }
}
