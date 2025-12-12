# Dapr Helm Release
resource "helm_release" "dapr" {
  name             = "dapr"
  repository       = "https://dapr.github.io/helm-charts/"
  chart            = "dapr"
  version          = var.dapr_version
  namespace        = "dapr-system"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      global = {
        logAsJson = true
      }
    })
  ]

  depends_on = [
    module.eks,
    null_resource.update_kubeconfig,
    time_sleep.wait_for_access_policy
  ]
}

# Metrics Server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  wait       = true

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls}"
  }

  depends_on = [
    module.eks,
    null_resource.update_kubeconfig,
    time_sleep.wait_for_access_policy
  ]
}
