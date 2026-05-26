locals {
  role_name        = "sentinel-github-actions-urinahshon"
  github_oidc_host = "token.actions.githubusercontent.com"
  github_oidc_url  = "https://${local.github_oidc_host}"

  github_oidc_arn = (
    var.create_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : data.aws_iam_openid_connect_provider.github[0].arn
  )
}