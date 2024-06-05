output "vpc_eu_central_1_id" {
  description = "ID of the eu-central-1 (client) VPC"
  value       = aws_vpc.Client_VPC-A.id
}

output "vpc_eu_west_3_id" {
  description = "ID of the eu-west-3 (partner) VPC"
  value       = aws_vpc.Partner_VPC-B.id
}

output "EC2-A_privateIP" {
  description = "Private IP of EC2-A:"
  value       = aws_instance.EC2-A.private_ip
}

output "EC2-B-Router_privateIP" {
  description = "Private IP of EC2-B-Router:"
  value       = aws_instance.EC2-B-Router.private_ip
}

output "EC2-B-Router_publicIP" {
  description = "Public IP of EC2-B-Router:"
  value       = aws_instance.EC2-B-Router.public_ip
}

output "EC2-C_privateIP" {
  description = "Public IP of EC2-C:"
  value       = aws_instance.EC2-C.private_ip
}
