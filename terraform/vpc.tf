#--------------------------------------------------
# Create VPC
#--------------------------------------------------
resource "aws_vpc" "imhio_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "imhio_vpc"
  }
}

#--------------------------------------------------
# Add AWS internet gateway
#--------------------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.imhio_vpc.id

  tags = {
    Name = "imhio_gw"
  }
}


#--------------------------------------------------
# CREATE EIP fot Web
#--------------------------------------------------
resource "aws_eip" "eip_web" {
  instance = aws_instance.imhio_web_host.id
  vpc      = true
}


#--------------------------------------------------
# CREATE EIP fot NAT Gateway
#--------------------------------------------------
resource "aws_eip" "eip_nat" {
  vpc      = true
}


#--------------------------------------------------
# CREATE NAT Gateway
#--------------------------------------------------
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip_nat.id
  subnet_id     = aws_subnet.imhio_public.id
}


#--------------------------------------------------
# Add AWS subnets (public)
#--------------------------------------------------
resource "aws_subnet" "imhio_public" {
  vpc_id     = aws_vpc.imhio_vpc.id
  cidr_block = var.imhio_public
  map_public_ip_on_launch = "true"
  tags = {
    Name = "imhio_public"
  }
}

#--------------------------------------------------
# Add AWS subnets (private)
#--------------------------------------------------
resource "aws_subnet" "imhio_private" {
  vpc_id     = aws_vpc.imhio_vpc.id
  cidr_block = var.imhio_private

  tags = {
    Name = "imhio_private"
  }
}

#--------------------------------------------------
# Add NACL rules
#--------------------------------------------------
resource "aws_network_acl" "imhio_public_nacl" {
  vpc_id = aws_vpc.imhio_vpc.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = var.ssh_white_ip
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = var.ssh_white_ip
    from_port  = 22
    to_port    = 22
  }

  tags = {
    Name = "imhio_public_nacl"
  }
}

#--------------------------------------------------
# Create public security group
#--------------------------------------------------
resource "aws_security_group" "public_sg_imhio" {
  name        = "public_sg_imhio"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.imhio_vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_white_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public_sg_imhio"
  }
}


#--------------------------------------------------
# Create private security group
#--------------------------------------------------
resource "aws_security_group" "private_sg_imhio" {
  name        = "allow_mongodb"
  description = "Allow MongoDB inbound traffic"
  vpc_id      = aws_vpc.imhio_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.imhio_web_host_private_ip]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.imhio_web_host_private_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private_sg_imhio"
  }
}

#--------------------------------------------------
# Create private route table
#--------------------------------------------------
resource "aws_route_table" "imhio_private_route" {
  vpc_id = aws_vpc.imhio_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
    }
    tags = {
    Name = "imhio_route_nat"
    }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.imhio_private.id
  route_table_id = aws_route_table.imhio_private_route.id
}

#--------------------------------------------------
# Create public route table
#--------------------------------------------------
resource "aws_route_table" "imhio_public_route" {
  vpc_id = aws_vpc.imhio_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
    Name = "imhio_route"
    }
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.imhio_public.id
  route_table_id = aws_route_table.imhio_public_route.id
}
