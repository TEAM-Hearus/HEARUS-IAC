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