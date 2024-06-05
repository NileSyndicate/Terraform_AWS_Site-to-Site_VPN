## Aim
In this project, we will use Terraform and AWS to build a Site-to-Site VPN connection between 2 different VPCs of disctinct CIDR ranges.  The aim is to model the business need of connecting 2 locations e.g. the company's AWS network and resources with its on-prem network.

The architecture of the solution is found here: /Architecture.png

This solution might incur some costs. Proceed at your own discretion, and do not forget to destroy your resources after finishing.

## Provisioned Resources
- 2 VPCs in different availability zones "eu-central-1" and "eu-west-3".
- 2 private and 1 public subnets. Each VPC created above will have 1 private subnet. Furthermore, VPC-B will also have a public subnet.
- 1 Site-to-Site VPN connection.
- 1 Customer Gateway.
- Virtual Private Gateway.
- 3 EC2 instances. EC2-A in private subnet-VPC1. EC2-B and EC2-C in the public and private subnets respectively in VPC2.
- 1 Internet Gateway that will be attached to VPC2 to allow external SSH.

## Installation
The following commands will initialize Terraform and the your AWS account to deploy the solution in, give you an overview of the deployment plan, and finally actually provision athe resources in your AWS account.
```
terraform init
terraform plan
terraform apply -auto-approve
```

To destroy the resources that were provisioned which is recommended to avoid extra charges, run the following
```
terraform destroy -auto-approve
```

