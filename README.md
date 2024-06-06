# Introduction
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

# Installation
## Terraform
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
## AWS
Log into your AWS account. Under eu-central-1 and eu-west-3 you will find the provisioned resources. Make sure that they were created correctly.

## VPN tunnels configuration
SSH into EC2-B-Router which resides in the public subnet of VPC2. This alows programatic access into your otherwise private environment. This EC2 acts as a bastion host to SSH into your other private EC2s.

Follow the steps in /LibreSwan_install_guide.txt to finalize the setup. Make sure to download the configuration file of the router of your choice. The configuration file can be downloaded from the AWS Console under "Site-to-Site VPN". In this project we are using LibreSwan. Download the file and follow the instructions.

If everything goes well, you should see the status of your Site-to-Site VPN tunnels' as "Up".

## Connectivity Test
from your bastion host (EC2-B-Router), SSH into one of the other private EC2s and run the python script file /custom_http_server.py
This will run a simple server that will be listening for connections on port 80, and will reply with a custom message.

SSH into the other EC2, and run the following:
```
curl -X GET <private_IP_of_simple_server>
```

You should receive the custom message with 200 OK status