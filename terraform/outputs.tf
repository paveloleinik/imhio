#-----------------------------------------------------------
# Main variables
#-----------------------------------------------------------

#-----------------------------------------------------------
# VPC variables
#-----------------------------------------------------------

output "vpc_id" {
  value = aws_vpc.imhio_vpc.id
}

output "account_id" {
  value = data.aws_caller_identity.current_id.account_id
}

output "web_sg_id" {
  value = aws_security_group.public_sg_imhio.id
}

output "db_sg_id" {
  value = aws_security_group.private_sg_imhio.id
}

output "private_web_cidr" {
  value = aws_subnet.imhio_public.cidr_block
}

output "private_db_cidr" {
  value = aws_subnet.imhio_private.cidr_block
}

#-----------------------------------------------------------
# EC2 variables
#-----------------------------------------------------------

output "web_public_ip" {
  value = aws_eip.eip_web.public_ip
}

output "web_private_ip" {
  value = aws_instance.imhio_web_host.private_ip
}

output "web_key_pair" {
  value = aws_instance.imhio_web_host.key_name
}

output "db_private_IP" {
  value = aws_instance.imhio_db_host.private_ip
}

output "db_key_pair" {
  value = aws_instance.imhio_db_host.key_name
}
