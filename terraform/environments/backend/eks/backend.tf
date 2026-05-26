terraform {
  backend "s3" {
    bucket       = "aws-vpc-eks-tfstate-721500739616"
    key          = "environments/backend/eks/terraform.tfstate"
    region       = "us-west-1"
    encrypt      = true
    use_lockfile = true
  }
}