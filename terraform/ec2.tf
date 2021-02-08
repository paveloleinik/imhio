
#--------------------------------------------------
# Create Network for web instance
#--------------------------------------------------
resource "aws_network_interface" "public_network_inr" {
  subnet_id   = aws_subnet.imhio_public.id
  private_ips = var.public_ip_web_instance
  security_groups = [aws_security_group.public_sg_imhio.id]
  tags = {
    Name = "public_network_interface"
  }
}

#--------------------------------------------------
# Create Network for DB instance
#--------------------------------------------------
resource "aws_network_interface" "private_network_inr" {
  subnet_id   = aws_subnet.imhio_private.id
  private_ips = var.private_ip_web_instance
  security_groups = [aws_security_group.private_sg_imhio.id]
  tags = {
    Name = "privet_network_interface"
  }
}


#--------------------------------------------------
# Create web instance
#--------------------------------------------------
resource "aws_instance" "imhio_web_host" {
  ami = var.ami
  key_name = var.key_name
  instance_type = var.instance_type
  network_interface {
    network_interface_id = aws_network_interface.public_network_inr.id
    device_index         = 0
  }
  tags = {
    Name = "imhio_web_host"
  }
  depends_on = [aws_instance.imhio_db_host]
  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------
# Create DB instance
#--------------------------------------------------
resource "aws_instance" "imhio_db_host" {
  ami = "ami-03d64741867e7bb94"
  instance_type = var.instance_type
  key_name = var.key_name
  ebs_block_device {
      device_name = "/dev/sdb"
      volume_size = "5"
      volume_type = "gp2"
      delete_on_termination = false
    }
  network_interface {
  network_interface_id = aws_network_interface.private_network_inr.id
  device_index         = 0
  }
  tags = {
  Name = "imhio_db_host"
  }
  lifecycle {
    create_before_destroy = true
  }
}
