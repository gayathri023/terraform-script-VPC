#vpc final

terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
    region = "ap-southeast-2"
}

# Create a VPC
resource "aws_vpc" "vpc_new" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name="MyVPC"
    }
}
#public subnet

resource "aws_subnet" "public_subnet" {
    vpc_id     = aws_vpc.vpc_new.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-southeast-2a"

tags = {
    Name = "PUBLIC SUBNET"
  }
}

#private subnet
resource "aws_subnet" "private_subnet" {
    vpc_id     = aws_vpc.vpc_new.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-southeast-2a"

tags = {
    Name = "PRIVATE SUBNET"
  }
}

#internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc_new.id

tags = {
    Name = "INTERNET GATEWAY"
  }
}

#route table

resource "aws_route_table" "publicrt" {
    vpc_id = aws_vpc.vpc_new.id

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


tags = {
    Name = "PUBLIC ROUTE TABLE"
  }
}


#route table association

resource "aws_route_table_association" "public_rt_association" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.publicrt.id
}


#elastic ip
resource "aws_eip" "eip" {
    domain   = "vpc"
}


#nat gateway
resource "aws_nat_gateway" "natgw" {
    allocation_id = aws_eip.eip.id
    subnet_id = aws_subnet.public_subnet.id
}

#private route table
resource "aws_route_table" "privatert" {
    vpc_id = aws_vpc.vpc_new.id
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }


  tags = {
    Name = "PRIVATE ROUTE TABLE"
  }
}

#private route table association

resource "aws_route_table_association" "private_rt_association" {
    subnet_id      = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.privatert.id
}

#public security group

resource "aws_security_group" "tf_pub_security" {
    name        = "Terraform public security group"
    description = "erraform security group"
    vpc_id      = aws_vpc.vpc_new.id

  tags = {
    Name = "TERRAFORM PUBLIC SG"
  }
resource "aws_vpc_security_group_ingress_rule" "https" {
    security_group_id = aws_security_group.tf_pub_security.id
    cidr_ipv4         = aws_vpc.vpc_new.cidr_block
    from_port         = 443
    ip_protocol       = "tcp"
    to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "windows" {
    security_group_id = aws_security_group.tf_pub_security.id
    cidr_ipv4         = aws_vpc.vpc_new.cidr_block
    from_port         = 3389
    ip_protocol       = "tcp"
    to_port           = 3389
    }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
    security_group_id = aws_security_group.tf_pub_security.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 0
    ip_protocol       = "-1" # semantically equivalent to all ports
    to_port           = 0
}


#private security group

resource "aws_security_group" "tf_prv_security" {
    name        = "Terraform private security group"
    description = "erraform security group"
    vpc_id      = aws_vpc.vpc_new.id

  tags = {
    Name = "TERRAFORM PRIVATE SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alltraffic" {
    security_group_id = aws_security_group.tf_prv_security.id
    cidr_ipv4         = aws_vpc.vpc_new.cidr_block
    from_port         = 0
    ip_protocol       = "tcp"
    to_port           = 65535
    }

resource "aws_vpc_security_group_egress_rule" "all_traffic_ipv4" {
    security_group_id = aws_security_group.tf_prv_security.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 0
    ip_protocol       = "-1" # semantically equivalent to all ports
    to_port           = 0
}

#instance 1

resource "aws_instance" "web1" {
    ami           = "ami-0fa4dfd1533851540" #windows
    instance_type = "t2.micro"
    availability_zone = "ap-southeast-2a"
    key_name = "dev"
    subnet_id     = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.tf_pub_security.id]
    associate_public_ip_address = true

  tags = {
    Name = "INSTANCE 1 PUBLIC"
  }
}


#instance 2

resource "aws_instance" "web0" {
    ami           = "ami-0fa4dfd1533851540" #windows
    instance_type = "t2.micro"
    availability_zone = "ap-southeast-2a"
    key_name = "dev"
    subnet_id     = aws_subnet.private_subnet.id
    vpc_security_group_ids = [aws_security_group.tf_prv_security.id]
    associate_public_ip_address = false

  tags = {
    Name = "INSTANCE 2 PRIVATE"
  }
}