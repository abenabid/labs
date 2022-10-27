# Bastion EC2 instance
resource "aws_instance" "bastion" {
  ami             = data.aws_ami.instance-image.id
  key_name        = aws_key_pair.key.key_name
  subnet_id       = module.vpc.public_subnets[0]
  instance_type   = "t2.small"
  vpc_security_group_ids = [
    aws_security_group.allow_all_from_vpc.id, 
    aws_security_group.allow_http.id, 
    aws_security_group.allow_ssh.id
  ]

  tags = {
    Name = "bastion"
  }

  user_data = templatefile("${path.module}/files/bastion_first_boot.sh", { 
    k3s_server = aws_instance.k3s_server.private_ip
    private_key_pem = tls_private_key.tls_key.private_key_pem
  })

}
