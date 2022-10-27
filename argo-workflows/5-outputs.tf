output "bastion_ip" {
  description = "Bastion's public IP"
  value       = aws_instance.bastion.public_ip
}

output "k3s_lb_dns" {
  description = "K3S Load Balancer DNS name"
  value       = aws_lb.k3s_lb.dns_name
}

output "k3s_server_ip" {
  description = "K3S Server private IPs"
  value       = aws_instance.k3s_server.private_ip
}

output "k3s_agents_ips" {
  description = "K3S Agents private IPs"
  value       = aws_instance.k3s_agent.*.private_ip
}
