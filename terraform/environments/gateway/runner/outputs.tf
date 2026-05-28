output "runner_instance_id" {
  description = "Use with: aws ssm start-session --target <id>"
  value       = aws_instance.runner.id
}