output "role_arn" {
  description = "ARN of the debug SSM role — use with: aws sts assume-role --role-arn <arn> --role-session-name debug"
  value       = aws_iam_role.debug_ssm.arn
}