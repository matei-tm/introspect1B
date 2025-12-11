# EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.public_subnets
  cluster_endpoint_public_access = true

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # EKS Managed Node Group
  eks_managed_node_groups = {
    main = {
      name           = "eks-lt-ng-public"
      instance_types = [var.node_instance_type]
      
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_capacity

      disk_size = 20
      disk_type = "gp3"

      ami_type = "AL2023_x86_64_STANDARD"

      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      tags = {
        Name = "${var.cluster_name}-node"
      }
    }
  }

  # Cluster access entry
#   enable_cluster_creator_admin_permissions = true

  # Add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }

  tags = {
    Name = var.cluster_name
  }
}
