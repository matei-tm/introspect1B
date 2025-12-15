# EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.public_subnets
  cluster_endpoint_public_access = true

  # Disable KMS encryption to avoid permission issues in lab environment
  create_kms_key = false
  cluster_encryption_config = {}

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Enable CloudWatch logging for EKS control plane
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # EKS Managed Node Group
  eks_managed_node_groups = {
    main = {
      name           = "eks-lt-ng-public"
      instance_types = [var.node_instance_type]
      
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_capacity

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

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
  }

  tags = {
    Name = var.cluster_name
  }
}

# Create EKS access entry for current IAM user
resource "aws_eks_access_entry" "admin_user" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = data.aws_caller_identity.current.arn
  type              = "STANDARD"
  
  depends_on = [module.eks]
}

# Associate admin policy with the access entry
resource "aws_eks_access_policy_association" "admin_user_policy" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin_user]
}

# Wait for access policy to propagate
resource "time_sleep" "wait_for_access_policy" {
  create_duration = "30s"

  depends_on = [aws_eks_access_policy_association.admin_user_policy]
}

# Update kubeconfig after access is granted
resource "null_resource" "update_kubeconfig" {
  depends_on = [time_sleep.wait_for_access_policy]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
  }

  triggers = {
    cluster_endpoint = module.eks.cluster_endpoint
    access_policy    = aws_eks_access_policy_association.admin_user_policy.id
  }
}

