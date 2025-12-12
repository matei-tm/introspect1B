# Kubernetes Namespace
resource "kubernetes_namespace" "dapr_demo" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }

  depends_on = [
    module.eks,
    null_resource.update_kubeconfig,
    time_sleep.wait_for_access_policy
  ]
}

# Kubernetes Service Account with IRSA
resource "kubernetes_service_account" "dapr" {
  metadata {
    name      = "dapr-service-account"
    namespace = kubernetes_namespace.dapr_demo.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.dapr_service_account.arn
    }
  }

  depends_on = [
    module.eks,
    null_resource.update_kubeconfig,
    time_sleep.wait_for_access_policy
  ]
}
