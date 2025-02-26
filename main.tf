provider "aws" {
  region = "us-east-1"
}

# VPC Creation
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  name    = "vibenova-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
}

# IAM Role for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "vibenova-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = module.vpc.public_subnets
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs" {
  name = "vibenova-ecs-cluster"
}

# API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "vibenova-api"
  protocol_type = "HTTP"
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "api_gateway_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
