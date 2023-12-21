provider "aws" {
  region = "ap-northeast-2"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

locals {
  cluster_name = "Hearus-project-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "Hearus-project-vpc"

  cidr = "172.21.0.0/16"
  azs  = ["ap-northeast-2a", "ap-northeast-2c"]

  private_subnets = ["172.21.1.0/24", "172.21.2.0/24"]
  public_subnets  = ["172.21.4.0/24", "172.21.5.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.cluster_name
  cluster_version = "1.28"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  cluster_security_group_id = aws_security_group.eks_cluster_sg.id

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group"

      instance_types = ["t3.small"]

      min_size     = 2
      max_size     = 2
      desired_size = 2
    }

  }
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks_cluster_sg"
  description = "Security group for EKS cluster"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "http" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "https" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_sg.id
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# 프로젝트 끝난 이후에 쓰지않는 권한들 삭제 예정
resource "aws_iam_role_policy" "eks_cluster_inline_policy" {
  name   = "eks-cluster-inline-policy"
  role   = aws_iam_role.eks_cluster_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
            "eks:DeleteFargateProfile",
            "eks:UpdateClusterVersion",
            "eks:ListEksAnywhereSubscriptions",
            "eks:DescribeFargateProfile",
            "eks:CreatePodIdentityAssociation",
            "eks:ListTagsForResource",
            "eks:UpdateAddon",
            "eks:ListAddons",
            "eks:UpdateClusterConfig",
            "eks:DescribeEksAnywhereSubscription",
            "eks:DescribeAddon",
            "eks:UpdateNodegroupVersion",
            "eks:DescribeNodegroup",
            "eks:AssociateEncryptionConfig",
            "eks:ListUpdates",
            "eks:DeleteEksAnywhereSubscription",
            "eks:CreateEksAnywhereSubscription",
            "eks:DescribeAddonVersions",
            "eks:DeletePodIdentityAssociation",
            "eks:ListIdentityProviderConfigs",
            "eks:UpdateEksAnywhereSubscription",
            "eks:CreateCluster",
            "eks:ListNodegroups",
            "eks:DisassociateIdentityProviderConfig",
            "eks:DescribeAddonConfiguration",
            "eks:CreateNodegroup",
            "eks:RegisterCluster",
            "eks:DeregisterCluster",
            "eks:UpdatePodIdentityAssociation",
            "eks:DescribePodIdentityAssociation",
            "eks:DeleteCluster",
            "eks:CreateFargateProfile",
            "eks:ListPodIdentityAssociations",
            "eks:ListFargateProfiles",
            "eks:DescribeIdentityProviderConfig",
            "eks:DeleteAddon",
            "eks:DeleteNodegroup",
            "eks:DescribeUpdate",
            "eks:TagResource",
            "eks:AccessKubernetesApi",
            "eks:CreateAddon",
            "eks:UpdateNodegroupConfig",
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:AssociateIdentityProviderConfig"
        ],
        "Resource": "*"
      }
    ]
  })
}

# EBS 설정
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.20.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}