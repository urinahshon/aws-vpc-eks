output "codebuild_role_arn" {
  description = "IAM role ARN assumed by both CodeBuild projects"
  value       = aws_iam_role.codebuild.arn
}

output "k8s_backend_project_name" {
  value = aws_codebuild_project.k8s_backend.name
}

output "k8s_gateway_project_name" {
  value = aws_codebuild_project.k8s_gateway.name
}