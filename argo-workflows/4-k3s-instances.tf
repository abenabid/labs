# K3s Cluster EC2 instances
resource "aws_instance" "k3s_server" {
  ami             = data.aws_ami.instance-image.id
  key_name        = aws_key_pair.key.key_name
  subnet_id       = module.vpc.private_subnets[0]
  instance_type   = "t3.medium"
  vpc_security_group_ids = [aws_security_group.allow_all_from_vpc.id, aws_security_group.allow_http.id]

  tags = {
    Name = "k3s-server"
  }

  user_data = templatefile("${path.module}/files/k3s_server_first_boot.sh", { 
    hostname = "k3s-server"
  })

}

# K3s Cluster EC2 instances
resource "aws_instance" "k3s_agent" {
  count           = 2
  ami             = data.aws_ami.instance-image.id
  key_name        = aws_key_pair.key.key_name
  subnet_id       = module.vpc.private_subnets[0]
  instance_type   = "t3.medium"
  vpc_security_group_ids = [aws_security_group.allow_all_from_vpc.id, aws_security_group.allow_http.id]

  tags = {
    Name = "k3s-agent-${count.index}"
  }

  user_data = templatefile("${path.module}/files/k3s_agent_first_boot.sh", { 
    hostname = "k3s-agent-${count.index}"
    k3s_server = aws_instance.k3s_server.private_ip
  })

}


resource "aws_lb" "k3s_lb" {
  name               = "k3s"
  internal           = false
  load_balancer_type = "network"
  subnets = module.vpc.public_subnets

}

resource "aws_lb_target_group" "k3s_lb" {
  name     = "k3s-lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "k3s_lb" {
  target_group_arn = aws_lb_target_group.k3s_lb.arn
  target_id        = aws_instance.k3s_server.id
  port             = 80
}

resource "aws_lb_listener" "k3s_lb" {
  load_balancer_arn = aws_lb.k3s_lb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_lb.arn
  }
}