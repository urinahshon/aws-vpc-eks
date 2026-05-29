locals {
  backend_cluster = "eks-backend"
  gateway_cluster = "eks-gateway"

  buildspec_backend = <<-BUILDSPEC
    version: 0.2

    phases:
      install:
        commands:
          - KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
          - curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
          - chmod +x kubectl && mv kubectl /usr/local/bin/kubectl

      pre_build:
        commands:
          - aws s3 sync s3://$${ARTIFACTS_BUCKET}/artifacts/k8s/backend/ k8s/backend/
          - aws eks update-kubeconfig --name $${BACKEND_CLUSTER} --region $${AWS_REGION} --alias eks-backend
          - sed -i "s|BACKEND_IRSA_ROLE_ARN|$${BACKEND_IRSA_ROLE_ARN}|g" k8s/backend/serviceaccount.yaml

      build:
        commands:
          - kubectl apply -f k8s/backend/namespace.yaml      --context=eks-backend
          - kubectl apply -f k8s/backend/serviceaccount.yaml --context=eks-backend
          - kubectl apply -f k8s/backend/networkpolicy.yaml  --context=eks-backend
          - kubectl apply -f k8s/backend/configmap.yaml      --context=eks-backend
          - kubectl apply -f k8s/backend/deployment.yaml     --context=eks-backend
          - kubectl apply -f k8s/backend/service.yaml        --context=eks-backend
          - kubectl rollout status deployment/backend -n sentinel-backend --context=eks-backend --timeout=300s

      post_build:
        commands:
          - |
            for i in $(seq 1 30); do
              H=$(kubectl get svc backend-service -n sentinel-backend --context=eks-backend \
                -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
              if [ -n "$H" ]; then
                echo "Internal NLB hostname: $H"
                aws ssm put-parameter \
                  --name /codebuild/backend-nlb-hostname \
                  --value "$H" \
                  --type String \
                  --overwrite \
                  --region "$${AWS_REGION}"
                break
              fi
              echo "Waiting for NLB... attempt $i/30"
              sleep 10
            done
            [ -z "$H" ] && { echo "ERROR: NLB hostname not ready after 5 minutes"; exit 1; }
  BUILDSPEC

  # Gateway post_build intentionally uses a single command block — CodeBuild runs each
  # list entry in a separate shell, so $H from the NLB-wait loop must be used in the
  # same block as the e2e validation rather than a second "- |" entry.
  buildspec_gateway = <<-BUILDSPEC
    version: 0.2

    phases:
      install:
        commands:
          - KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
          - curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
          - chmod +x kubectl && mv kubectl /usr/local/bin/kubectl

      pre_build:
        commands:
          - aws s3 sync s3://$${ARTIFACTS_BUCKET}/artifacts/k8s/gateway/ k8s/gateway/
          - aws eks update-kubeconfig --name $${GATEWAY_CLUSTER} --region $${AWS_REGION} --alias eks-gateway
          - sed -i "s|BACKEND_HOST|$${NLB_HOSTNAME}|g"                   k8s/gateway/configmap.yaml
          - sed -i "s|GATEWAY_IRSA_ROLE_ARN|$${GATEWAY_IRSA_ROLE_ARN}|g" k8s/gateway/serviceaccount.yaml

      build:
        commands:
          - kubectl apply -f k8s/gateway/namespace.yaml      --context=eks-gateway
          - kubectl apply -f k8s/gateway/serviceaccount.yaml --context=eks-gateway
          - kubectl apply -f k8s/gateway/networkpolicy.yaml  --context=eks-gateway
          - kubectl apply -f k8s/gateway/configmap.yaml      --context=eks-gateway
          - kubectl apply -f k8s/gateway/deployment.yaml     --context=eks-gateway
          - kubectl apply -f k8s/gateway/service.yaml        --context=eks-gateway
          - kubectl rollout status deployment/gateway -n sentinel-gateway --context=eks-gateway --timeout=300s

      post_build:
        commands:
          - |
            for i in $(seq 1 30); do
              H=$(kubectl get svc gateway-service -n sentinel-gateway --context=eks-gateway \
                -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
              if [ -n "$H" ]; then
                echo "Gateway NLB hostname: $H"
                break
              fi
              echo "Waiting for gateway NLB... attempt $i/30"
              sleep 10
            done
            [ -z "$H" ] && { echo "ERROR: Gateway NLB hostname not ready after 5 minutes"; exit 1; }
            URL="http://$H"
            for i in $(seq 1 18); do
              BODY=$(curl -sf --max-time 10 "$URL" 2>/dev/null || true)
              if echo "$BODY" | grep -q "Hello from"; then
                echo "E2E validation passed — response: $BODY"
                exit 0
              fi
              echo "Attempt $i/18 — got: '$${BODY:-<no response>}' — retry in 10s"
              sleep 10
            done
            echo "ERROR: E2E validation failed after 3 minutes"
            exit 1
  BUILDSPEC
}

resource "aws_cloudwatch_log_group" "k8s_backend" {
  name              = "/codebuild/k8s-deploy-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "k8s_gateway" {
  name              = "/codebuild/k8s-deploy-gateway"
  retention_in_days = 7
}

# Backend deploy — runs inside the backend VPC to reach the private EKS API endpoint.
resource "aws_codebuild_project" "k8s_backend" {
  name          = "k8s-deploy-backend"
  description   = "Deploy k8s workloads to the private backend EKS cluster"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 20

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "BACKEND_CLUSTER"
      value = local.backend_cluster
    }
    environment_variable {
      name  = "ARTIFACTS_BUCKET"
      value = var.tf_state_bucket
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = local.buildspec_backend
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  vpc_config {
    vpc_id             = data.terraform_remote_state.backend_network.outputs.vpc_id
    subnets            = data.terraform_remote_state.backend_network.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.codebuild_backend.id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.k8s_backend.name
      stream_name = "build"
    }
  }

  tags = {
    Name = "k8s-deploy-backend"
  }
}

# Gateway deploy — no VPC needed; the gateway EKS API endpoint is public.
resource "aws_codebuild_project" "k8s_gateway" {
  name          = "k8s-deploy-gateway"
  description   = "Deploy k8s workloads to the public gateway EKS cluster"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 20

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "GATEWAY_CLUSTER"
      value = local.gateway_cluster
    }
    environment_variable {
      name  = "ARTIFACTS_BUCKET"
      value = var.tf_state_bucket
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = local.buildspec_gateway
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.k8s_gateway.name
      stream_name = "build"
    }
  }

  tags = {
    Name = "k8s-deploy-gateway"
  }
}