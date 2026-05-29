output "instance_id" {
  description = "Connect via: aws ssm start-session --target <instance_id> --region us-west-1"
  value       = aws_instance.bastion.id
}

output "private_ip" {
  value = aws_instance.bastion.private_ip
}