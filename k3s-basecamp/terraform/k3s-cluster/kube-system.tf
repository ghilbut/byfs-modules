resource null_resource kube_system {
  depends_on = [
    null_resource.k3s_cluster,
  ]
  triggers = {
    scripts = md5("${path.module}/scripts/install-kube-system-by-argo.sh"),
  }

  provisioner local-exec {
    command     = "${path.module}/scripts/install-kube-system-by-argo.sh"
    environment = {
      CONFIG   = var.argoconfig
      REVISION = "featrue/k3s-basecamp-terraform"
      #REVISION = local.revision
      SERVER   = local.argo_host
    }
  }
}
