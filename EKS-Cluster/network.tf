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