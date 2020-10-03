/*
provider kubernetes {
  config_path = var.kubeconfig
}

resource kubernetes_namespace k8s_dashboard {
  depends_on = [
    null_resource.manager_argo,
  ]

  metadata {
    name = "k8s-dashboard"
  }
}

resource null_resource k8s_dashboard {
  depends_on = [
    kubernetes_namespace.k8s_dashboard,
  ]
  triggers = {
    scripts = md5("${path.module}/scripts/install-k8s-dashboard-by-argo.sh"),
  }

  provisioner local-exec {
    command     = "${path.module}/scripts/install-k8s-dashboard-by-argo.sh"
    environment = {
      CONFIG   = var.argoconfig
      REVISION = local.revision
      SERVER   = local.argo_host
    }
  }
}
*/
