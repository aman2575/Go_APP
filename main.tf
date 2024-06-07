# main.tf
provider "aws" {
  region = "us-west-2"
}

# VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "eks-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "eks_public_subnets" {
  count = 2
  cidr_block = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  vpc_id     = aws_vpc.eks_vpc.id
  availability_zone = "us-west-2a"
  tags = {
    Name = "eks-public-subnet-${count.index}"
  }
}

# Private Subnets
resource "aws_subnet" "eks_private_subnets" {
  count = 2
  cidr_block = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index + 2)
  vpc_id     = aws_vpc.eks_vpc.id
  availability_zone = "us-west-2a"
  tags = {
    Name = "eks-private-subnet-${count.index}"
  }
}

# Security Group
resource "aws_security_group" "eks_sg" {
  name        = "eks-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.eks_vpc.id

  # Allow inbound traffic on port 22 (SSH)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic on port 443 (HTTPS)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role
resource "aws_iam_role" "eks_iam_role" {
  name        = "eks-iam-role"
  description = "IAM role for EKS cluster"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM Policy
resource "aws_iam_policy" "eks_iam_policy" {
  name        = "eks-iam-policy"
  description = "IAM policy for EKS cluster"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "eks:*",
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "eks_iam_role_policy_attachment" {
  role       = aws_iam_role.eks_iam_role.name
  policy_arn = aws_iam_policy.eks_iam_policy.arn
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_id  = aws_vpc.eks_vpc.id
  subnets = aws_subnet.eks_private_subnets.*.id

  depends_on = [aws_iam_role_policy_attachment.eks_iam_role_policy_attachment]
}

# EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "my-eks-node-group"
  node_role_arn   = aws_iam_role.eks_iam_role.arn

  subnet_ids = aws_subnet.eks_private_subnets.*.id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }
}

# IAM Role for Node Group
resource "aws_iam_role" "eks_node_group_iam_role" {
  name        = "eks-node-group-iam-role"
  description = "IAM role for EKS node group"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM Policy for Node Group
resource "aws_iam_policy" "eks_node_group_iam_policy" {
  name        = "eks-node-group-iam-policy"
  description = "IAM policy for EKS node group"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "ec2:*",
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# IAM Role Policy Attachment for Node Group
resource "aws_iam_role_policy_attachment" "eks_node_group_iam_role_policy_attachment" {
  role       = aws_iam_role.eks_node_group_iam_role.name
  policy_arn = aws_iam_policy.eks_node_group_iam_policy.arn
}
