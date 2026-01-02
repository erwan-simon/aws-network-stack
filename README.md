# Network

This terraform stack creates the network configuration needed for every cloud project.

**WARNING: some elements of this stack COST MONEY as long as they are deployed, do not forget to destroy them when not needed. See dedicated chapter in this documentation**

## Prerequisites

You need to deploy the [terraform backend](https://gitlab.revolve.team/erwan.simon/terraform-backend/).

You do not need anything else for local deployment.

Before deploying this stack via Gitlab CI, you first need to :
* deploy the [Docker images for your CI pipelines](https://gitlab.revolve.team/erwan.simon/devops-platform-ci-images)
* deploy the [IAM role which grants Gitlab CI access to your AWS account](https://gitlab.revolve.team/erwan.simon/devops-platform-ci-images)
* ensure that your repository has access to the [CI templates repository](https://gitlab.revolve.team/erwan.simon/devops-platform-ci-templates/)
* add to your Gitlab repository CI/CD variables the `ACCOUNT_ID` with the ID of your AWS account

## General presentation

This configuration is composed of multiple elements :

- a VPC
- 3 groups of subnets :
  - a public subnet : which cas be accessed from internet (resources created in this subnet by default are affected with a public IP address) and can access internet (with the Internet Gateway created in this subnet)
  - a private subnet : which can access internet using the NAT Gateway created in the public subnet but cannot be accessed from the internet (resources in it are not created with a public IP address by default)
  - an intra subnet : resources created in this subnet cannot access internet and cannot be accessed from the internet
- an Internet Gateway : resource allowing the public and private subnets to have access to the internet
- a NAT Gateway : resource located in the public subnet allowing the private subnets to have access to the internet

## How to deploy

Before deployment, you need to provide some variable values to avoid collision with tenants of this stack in other accounts in the following files:
* the `bucket` and `dynamodb_table` values of the terraform backend in the [iac/terraform.tf](iac/terraform.tf) file. Make them match with the values you used in the terraform backend stack.
* the `git_repository` and `project_name` value in the [iac/terraform.tfvars](iac/terraform.tfvars) file.
* the `PROJECT_NAME` variable value and the `project` uri in the [.gitlab-ci.yml](./.gitlab-ci.yml) file


### Local

To deploy locally:
```bash
cd iac
terraform init -backend-config="bucket=$TERRAFORM_BACKEND_BUCKET" -backend-config="dynamodb_table=$TERRAFORM_BACKEND_DYNAMODB"
terraform workspace new prod
terraform apply
```

### CI

```bash
git init
git add .
git remote add origin https://my-repo.git
git checkout -b prod
git commit -m "feat: init repo"
git push
```

## Destroy costly infrastructure

You can destroy the NAT gateway and the Elastic IP when you are not using the Internet Egress capabilities of the private subnets of this network stack.

```bash
cd iac
terraform init -backend-config="bucket=$TERRAFORM_BACKEND_BUCKET" -backend-config="dynamodb_table=$TERRAFORM_BACKEND_DYNAMODB"
terraform workspace select prod
terraform destroy -target aws_nat_gateway.instances -target aws_eip.nat_eips
```

If you are using Gitlab CI, you can also destroy those resources directly from the pipeline using the `destroy-nat-gateway` step.

You also have the possibility to schedule the execution of the `terraform_apply_schedule` which will create all resources and the `terraform_destroy_schedule` which will destroy only the resources that cast money using [Gitlab CI pipeline schedules](https://docs.gitlab.com/ee/ci/pipelines/schedules.html). It is usefull for example if you have scheduled workload in your account.
