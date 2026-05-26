output "ci_role_arn" {
  description = "ARN of the terraform-ci-role assumed by GitHub Actions"
  value       = aws_iam_role.ci.arn
}

output "ci_role_name" {
  description = "Name of the terraform-ci-role"
  value       = aws_iam_role.ci.name
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = local.github_oidc_arn
}