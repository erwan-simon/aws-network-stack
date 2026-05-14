# network-platform

A Terraform stack that gives any AWS account a **production-ready VPC baseline in one apply** — and that proves it works before handing it over.

What you get:

- A standard 3-tier VPC (`public` / `private` / `intra`) spread across every AZ of the region, with the routing already wired up.
- A built-in **functional test**: a Lambda deployed in the private subnets is invoked on every apply and fails the run if egress through the NAT Gateway is broken. No more "the apply succeeded but nothing can reach the internet".
- A **cost-control lifecycle**: the NAT Gateway and Elastic IP — the only resources that cost money while idle — can be destroyed and recreated on a schedule via GitLab CI, so dev/staging accounts don't bleed money overnight.

Designed as one brick of a larger platform (alongside [terraform-backend](https://gitlab.revolve.team/erwan.simon/terraform-backend/), [devops-platform-ci-images](https://gitlab.revolve.team/erwan.simon/devops-platform-ci-images), and [devops-platform-ci-templates](https://gitlab.revolve.team/erwan.simon/devops-platform-ci-templates/)), but the stack stands on its own for local use.

## Architecture

```
                          ┌──────────────────────────┐
                          │         Internet         │
                          └────────────┬─────────────┘
                                       │
                              ┌────────┴────────┐
                              │ Internet Gateway│
                              └────────┬────────┘
   VPC 10.0.0.0/16                     │
   ┌────────────────────────────────────────────────────────────────┐
   │  Public  10.0.48.0/20  …    ──►  NAT GW  ──►                   │
   │                                     │                          │
   │  Private 10.0.0.0/20   …  ──────────┘   (egress only)          │
   │                                                                │
   │  Intra   10.0.96.0/20  …    (no internet, in or out)           │
   └────────────────────────────────────────────────────────────────┘
```

One subnet per tier per AZ. NAT Gateway count is configurable via `nat_gateways_count` (default `1`, shared across AZs); private route tables fan out to whichever NAT exists.

## Quick start (local)

Prerequisite: the [terraform-backend](https://gitlab.revolve.team/erwan.simon/terraform-backend/) stack deployed in the target account.

```bash
cd iac
cp backend.hcl.example backend.hcl              # then edit with your backend bucket/table
cp terraform.tfvars.example terraform.tfvars    # then edit with your project values
terraform init -backend-config=backend.hcl
terraform workspace new prod
terraform apply
```

The apply runs the functional-test Lambda at the end — if egress is broken, the apply fails.

`iac/backend.hcl` holds the `bucket` and `dynamodb_table` of your [terraform-backend](https://gitlab.revolve.team/erwan.simon/terraform-backend/) deployment — edit it once per account. In CI the same two values are passed as `$TERRAFORM_BACKEND_BUCKET` / `$TERRAFORM_BACKEND_DYNAMODB` from the template.

## Configuration

Before deploying in a new account, edit:

| File | Field | Why |
| --- | --- | --- |
| `iac/terraform.tf` | `dynamodb_table` (and the `bucket` via `-backend-config`) | Must match your terraform-backend deployment |
| `iac/terraform.tfvars` | `project_name`, `git_repository` | Used in tags and resource names |
| `.gitlab-ci.yml` | `PROJECT_NAME`, included templates `project:` ref | Only if you deploy via GitLab CI |

Tunable inputs (see `iac/variables.tf`): `private_subnet`, `public_subnet`, `intra_subnet` (CIDR lists, one per AZ), and `nat_gateways_count`.

## CI

A `.gitlab-ci.yml` is provided for reference but depends on private templates that aren't publicly accessible — treat it as a blueprint to wire an equivalent pipeline on your own CI (GitHub Actions, etc.). The pattern is straightforward: branches map to Terraform workspaces, and two scheduled jobs (`SCHEDULE_NAME=create` / `SCHEDULE_NAME=destroy`) cycle the NAT Gateway + EIP to cap costs on non-production accounts.

## Cost control

> ⚠️ The NAT Gateway and its Elastic IP cost money 24/7 as long as they exist (~$30–35/month each in `eu-west-1`, plus data processing). Destroy them when idle.

Manually, locally or from any branch:

```bash
cd iac
terraform init -backend-config=backend.hcl
terraform workspace select prod
terraform destroy -target aws_nat_gateway.instances -target aws_eip.nat_eips
```

From the GitLab pipeline: the manual `destroy-nat-gateway` job does the same thing. The rest of the VPC is free and stays up.

## License

See [LICENSE](LICENSE).
