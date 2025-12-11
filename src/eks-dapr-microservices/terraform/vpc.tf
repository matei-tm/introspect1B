# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  public_subnets  = [var.public_subnet_1_cidr, var.public_subnet_2_cidr]

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Enable auto-assign public IP for public subnets
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}
