
####################################
## VPC-A (Client) and 1 Private Subnet Creation ##
####################################

resource "aws_vpc" "Client_VPC-A" {
  provider   = aws
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Client_VPC-A"
  }
}

resource "aws_subnet" "VPC-A_private-subnet" {
  vpc_id            = aws_vpc.Client_VPC-A.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "VPC-A_private-subnet"
  }
}

#####################################
## VPC-B (Partner) , 1 Private Subnet, 1 Public Subnet Creation ##
#####################################

resource "aws_vpc" "Partner_VPC-B" {
  provider   = aws.eu_west
  cidr_block = "20.0.0.0/16"

  tags = {
    Name = "Partner_VPC-B"
  }
}

resource "aws_subnet" "VPC-B_Private_Subnet" {
  provider          = aws.eu_west
  vpc_id            = aws_vpc.Partner_VPC-B.id
  cidr_block        = "20.0.1.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "VPC-B_Private_Subnet"
  }
}

resource "aws_subnet" "VPC_B_public_subnet" {
  provider          = aws.eu_west
  vpc_id            = aws_vpc.Partner_VPC-B.id
  cidr_block        = "20.0.2.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "VPC_B_public_subnet"
  }
}

resource "aws_network_interface" "ENI_VPC-B_public-subnet" {
  provider          = aws.eu_west
  subnet_id         = aws_subnet.VPC_B_public_subnet.id
  security_groups   = [aws_security_group.EC2-B-Router_SG.id]
  source_dest_check = false
  attachment {
    instance     = aws_instance.EC2-B-Router.id
    device_index = 1
  }

  tags = {
    Name = "ENI_EC2-B-Router"
  }
}

#########################
## 1 EC2 (Client) in Private Subnet VPN-A Creation ##
#########################

resource "aws_instance" "EC2-A" {
  provider                    = aws
  ami                         = "ami-098c93bd9d119c051"
  instance_type               = "t2.micro"                         // Free Tier t2.micro
  subnet_id                   = aws_subnet.VPC-A_private-subnet.id // launch in client private subnet
  vpc_security_group_ids      = [aws_security_group.EC2-A_SG.id]
  key_name                    = "OpenVPN_key"
  associate_public_ip_address = false // No public IP to be associated with this EC2 as it is in private subnet

  tags = {
    Name = "EC2-A"
  }
}

###############################################
## 1 EC2 (Partner) in Private Subnet & 1 EC2 (Router) in Public Subnet VPN-B Creation ##
###############################################

resource "aws_instance" "EC2-B-Router" {
  provider                    = aws.eu_west
  ami                         = "ami-0111c5910da90c2a7"
  instance_type               = "t2.micro"                        // Free Tier t2.micro
  subnet_id                   = aws_subnet.VPC_B_public_subnet.id // launch in partner public subnet
  source_dest_check           = false                             // Disable source/dest checks
  vpc_security_group_ids      = [aws_security_group.EC2-B-Router_SG.id]
  key_name                    = "OpenVPN_key2"
  associate_public_ip_address = true // Will be placed in the Public Partner subnet

  tags = {
    Name = "EC2-B-Router"
  }

#   network_interface {
#     device_index            = 1
#     network_interface_id    = aws_network_interface.ENI_VPC-B_public-subnet.id
# }
}

resource "aws_instance" "EC2-C" {
  provider               = aws.eu_west
  ami                    = "ami-0111c5910da90c2a7"
  instance_type          = "t2.micro"                         // Free Tier t2.micro
  subnet_id              = aws_subnet.VPC-B_Private_Subnet.id // launch in partner private subnet
  vpc_security_group_ids = [aws_security_group.EC2-C_SG.id]
  key_name               = "OpenVPN_key2"
  //user_data = 
  associate_public_ip_address = false // Will be placed in the Private Partner subnet

  tags = {
    Name = "EC2-C"
  }
}


#####################################
## RT private subnet in VPC-A Creation ##
#####################################
resource "aws_route_table" "VPC-A_private-subnet_RT" {
  vpc_id           = aws_vpc.Client_VPC-A.id
  propagating_vgws = [aws_vpn_gateway.VPC-A_VPGW.id]
  tags = {
    Name = "VPC-A_private-subnet_RT"
  }
}


resource "aws_route_table_association" "VPC-A_private-subnet_RT_association" {
  subnet_id      = aws_subnet.VPC-A_private-subnet.id
  route_table_id = aws_route_table.VPC-A_private-subnet_RT.id

}
#####################################
## RT private subnet in VPC-B Creation ##
#####################################
resource "aws_route_table" "VPC-B_private-subnet_RT" {
  provider = aws.eu_west
  vpc_id   = aws_vpc.Partner_VPC-B.id

  tags = {
    Name = "VPC-B_private-subnet_RT"
  }
}

resource "aws_route" "r1_VPC-B_private_subnet" {
  provider               = aws.eu_west
  route_table_id         = aws_route_table.VPC-B_private-subnet_RT.id
  destination_cidr_block = "10.0.0.0/16"
  network_interface_id   = aws_network_interface.ENI_VPC-B_public-subnet.id
  # network_interface_id   = aws_network_interface.ENI_VPC-B_public-subnet.id

}

resource "aws_route_table_association" "VPC-B_private-subnet_RT_association" {
  provider       = aws.eu_west
  subnet_id      = aws_subnet.VPC-B_Private_Subnet.id
  route_table_id = aws_route_table.VPC-B_private-subnet_RT.id

}

#####################################
## RT public subnet in VPC-B Creation ##
#####################################
resource "aws_route_table" "VPC-B_public-subnet_RT" {
  provider = aws.eu_west
  vpc_id   = aws_vpc.Partner_VPC-B.id

  tags = {
    Name = "VPC-B_public-subnet_RT"
  }
}

resource "aws_route" "r1_VPC-B_public_subnet" {
  provider               = aws.eu_west
  route_table_id         = aws_route_table.VPC-B_public-subnet_RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.VPC-B_IGW.id
}

resource "aws_route_table_association" "VPC-B_public-subnet_RT_association" {
  provider       = aws.eu_west
  subnet_id      = aws_subnet.VPC_B_public_subnet.id
  route_table_id = aws_route_table.VPC-B_public-subnet_RT.id

}

#####################################
## EC2-A SG In VPC-A Creation ##
#####################################
resource "aws_security_group" "EC2-A_SG" {
  name        = "EC2-A_SG"
  description = "Allow ICMP and TCP traffic from VPC-B"
  vpc_id      = aws_vpc.Client_VPC-A.id

  tags = {
    Name = "EC2-A_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ICMP_EC2-A_SG" {
  security_group_id = aws_security_group.EC2-A_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTP_EC2-A_SG" {
  security_group_id = aws_security_group.EC2-A_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTPS_EC2-A_SG" {
  security_group_id = aws_security_group.EC2-A_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH_EC2-A_SG" {
  security_group_id = aws_security_group.EC2-A_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_EC2-A_SG" {
  security_group_id = aws_security_group.EC2-A_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#######################################
## EC2-B-Router SG In VPC-B Creation ##
#######################################

resource "aws_security_group" "EC2-B-Router_SG" {
  provider    = aws.eu_west
  name        = "EC2-B-Router_SG"
  description = "Allow SSH from Internet, ICMP and TCP traffic from VPC-A & VPC-B"
  vpc_id      = aws_vpc.Partner_VPC-B.id

  tags = {
    Name = "EC2-B-Router_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ICMP_EC2-B_SG_VPC-A" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-B-Router_SG.id
  cidr_ipv4         = aws_vpc.Client_VPC-A.cidr_block
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_ICMP_EC2-B_SG_VPC-B" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-B-Router_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH_EC2-B_SG" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-B-Router_SG.id
  cidr_ipv4         = "0.0.0.0/0" // For dev environment. Should be restricted in the future to a specific trusted IP
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTP_EC2-B_SG_VPC-A" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-B-Router_SG.id
  cidr_ipv4         = aws_vpc.Client_VPC-A.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTPS_EC2-B_SG_VPC-A" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-B-Router_SG.id
  cidr_ipv4         = aws_vpc.Client_VPC-A.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTP_EC2-B_SG_VPC-B" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-B-Router_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTPS_EC2-B_SG_VPC-B" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-B-Router_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_EC2-B_SG" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-B-Router_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#####################################
## EC2-C SG In VPC-B Creation ##
#####################################
resource "aws_security_group" "EC2-C_SG" {
  provider    = aws.eu_west
  name        = "EC2-C_SG"
  description = "Allow SSH from EC2-B-Router, ICMP and TCP traffic from VPC-A & VPC-B"
  vpc_id      = aws_vpc.Partner_VPC-B.id

  tags = {
    Name = "EC2-C_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ICMP_EC2-C_SG_VPC-A" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-C_SG.id
  cidr_ipv4         = aws_vpc.Client_VPC-A.cidr_block
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_ICMP_EC2-C_SG_VPC-B" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-C_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH_EC2-C_SG" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-C_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block // Allow SSH only from VPC-B, i.e. EC2-B-router
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTP_EC2-C_SG_VPC-A" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-C_SG.id
  cidr_ipv4         = aws_vpc.Client_VPC-A.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTPS_EC2-C_SG_VPC-A" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-C_SG.id
  cidr_ipv4         = aws_vpc.Client_VPC-A.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTP_EC2-C_SG_VPC-B" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-C_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_TCP_HTTPS_EC2-C_SG_VPC-B" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-C_SG.id
  cidr_ipv4         = aws_vpc.Partner_VPC-B.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_EC2-C_SG" {
  provider          = aws.eu_west
  security_group_id = aws_security_group.EC2-C_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


###############################################
## Internet Gateway Creation in VPC-B ##
###############################################
resource "aws_internet_gateway" "VPC-B_IGW" {
  provider = aws.eu_west
  vpc_id   = aws_vpc.Partner_VPC-B.id

  tags = {
    Name = "VPC-B_IGW"
  }
}



###############################
## Customer Gateway Creation ##
###############################
resource "aws_customer_gateway" "VPC-B_CGW" {
  provider   = aws
  bgp_asn    = 65000
  ip_address = aws_instance.EC2-B-Router.public_ip //set the CGW to the Public IP of EC2-B-Router
  type       = "ipsec.1"

  tags = {
    Name = "VPC-B_CGW"
  }
}

###############################################
## Virtual Private Gateway Creation ##
###############################################
resource "aws_vpn_gateway" "VPC-A_VPGW" {
  provider = aws
  vpc_id   = aws_vpc.Client_VPC-A.id

  tags = {
    Name = "VPC-A_VPGW"
  }
}

###############################################
## Site-to-Site VPN Creation ##
###############################################
resource "aws_vpn_connection" "S2S_VPN-A_VPN-B" {
  provider            = aws
  vpn_gateway_id      = aws_vpn_gateway.VPC-A_VPGW.id
  customer_gateway_id = aws_customer_gateway.VPC-B_CGW.id
  type                = "ipsec.1"
  #   local_ipv4_network_cidr = "20.0.0.0/16"
  #   remote_ipv4_network_cidr = "10.0.0.0/16"
  static_routes_only = true

  tags = {
    Name = "S2S_VPN-A_VPN-B"
  }
}

resource "aws_vpn_connection_route" "VPN_staticIP" {
  destination_cidr_block = "20.0.0.0/16"
  vpn_connection_id      = aws_vpn_connection.S2S_VPN-A_VPN-B.id
}


