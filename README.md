# Project Title

In this project, we will use Terraform and AWS to provision the following:
- 2 VPCs in different availability zones "eu-central-1" and "eu-west-3"
- 2 private and 1 public subnets. Each VPC created above will have 1 private subnet. Furthermore, VPC-B will also have a public subnet
- 1 Site-to-Site VPN connection
- 1 Customer Gateway
- Virtual Private Gateway
- 3 EC2 instances. EC2-A in private subnet-VPC1. EC2-B and EC2-C in the public and private subnets respectively in VPC2

## Installation



```bash
terraform init
terraform plan
terraform apply -auto-approve