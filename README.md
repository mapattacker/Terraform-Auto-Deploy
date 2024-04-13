# Terraform-Auto-Deploy

A demonstration on how to deploy a container to an EC2 instance using SSM Run Command, Ansible and docker compose.

## Infrastructure Setup

1. Save your aws credentials in `aws configure`
2. Edit the `var.auto.tfvars` file to use your own variables
3. `terraform init` > `terraform apply` to launch the infrastructure
4. Test the deployment is works using SSM Run Command by running `bash scripts/deploy.sh`

## Infrastruture Teardown

1. Remove S3 and ECR contents by first running `bash scripts/destroy.sh`
2. Run `terraform destroy`

## AWS user for CI

1. Use the policy in dir `user/policy.json` to create an AWS user for your CI pipeline
