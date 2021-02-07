#-----------------------------------------------------------
# Main variables
#-----------------------------------------------------------

variable "access_key" {
  description = "Enter your access key for AWS user"
#  default     = ""
}

variable "secret_key" {
  description = "Enter your secret key for AWS user"
#  default     = ""
}

variable "region" {
  description = "Enter AWS Region to deploy Server"
  default     = "us-east-2"
}

#-----------------------------------------------------------
# VPC variables
#-----------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block of VCP"
  default     = "10.0.0.0/16"
}

variable "imhio_public" {
  description = "CIDR block of imhio public"
  default     = "10.0.1.0/24"
}

variable "imhio_private" {
  description = "CIDR block of imhio private"
  default     = "10.0.2.0/24"
}

variable "ssh_white_ip" {
  description = "ssh_white_ip"
  default     = "95.24.123.157/32"
}

variable "allow_ports" {
  description = "List of Ports to opem for server"
  type        = list
  default     = ["443", "80", "22"]
}

#-----------------------------------------------------------
# EC2 variables
#-----------------------------------------------------------

variable "ami" {
  description = "AIM for instances"
  default     = "ami-03d64741867e7bb94"
}

variable "imhio_web_host_private_ip" {
  description = "imhio_web_host_private_ip"
  default     = "10.0.1.100/32"
}

variable "imhio_db_host_private_ip" {
  description = "imhio_db_host_private_ip"
  default     = "10.0.2.200/32"
}

variable "imhio_ebs_db_type" {
  description = "imhio_ebs_db_type"
  default     = "gp2"
}
variable "imhio_ebs_db" {
  description = "EBS DB Size"
  default     = "5"
}

variable "key_name" {
  description = "Key pair for connect to EC2"
  default     = "key"
}

variable "instance_type" {
  description = "instance_type"
  default     = "t2.micro"
}

variable "public_ip_web_instance" {
  description = "public_ip_web_instance"
  default     = ["10.0.1.100"]
}

variable "private_ip_web_instance" {
  description = "private_ip_web_instance"
  default     = ["10.0.2.200"]
}
