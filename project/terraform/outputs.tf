output "controller_public_ip" {
  value = aws_instance.controller.public_ip
}

output "target_ips" {
  value = [for instance in aws_instance.targets : instance.public_ip]
}
