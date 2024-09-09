module "eks" {
  depends_on = [ module.vpc ]
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "guardian-cluster"
  cluster_version = "1.30"

  # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    amazon-cloudwatch-observability = {
        service_account_role_arn = "arn:aws:iam::721699489018:role/guardian-monitoring"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

    eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.medium"]

      min_size     = 4
      max_size     = 6
      desired_size = 4
    }

    
  }

  
}

