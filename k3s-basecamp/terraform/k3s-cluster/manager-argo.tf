resource random_password argo {
  length           = 12
  special          = true
  override_special = "!@#$%^&*()"
}

resource null_resource manager_argo {
  depends_on = [
    null_resource.k3s_cluster,
    null_resource.k8s_network,
  ]
  triggers = {
    scripts = md5(join(
      "\n",
      [
        filebase64("${path.module}/scripts/install-manager-argo.sh"),
        filebase64("${path.module}/scripts/login-argocd.sh"),
        filebase64("${path.module}/scripts/bind-manager-argo-to-argo.sh"),
      ]
    ))
    kubeconfig = var.kubeconfig
    argoconfig = var.argoconfig
  }

  provisioner local-exec {
    command     = "${path.module}/scripts/install-manager-argo.sh"
    environment = {
      KUBECONFIG           = var.kubeconfig
      HELM_CHART_PATH      = "${local.helmchart_path}/manager-argo/"
      HOST                 = local.argo_host
      ARGO_PASSWORD        = random_password.argo.result
      GITHUB_CLIENT_ID     = var.argo_github_client_id
      GITHUB_CLIENT_SECRET = var.argo_github_client_secret
    }   
  }

  provisioner local-exec {
    command     = "${path.module}/scripts/login-argocd.sh"
    environment = {
      ARGOCONFIG      = var.argoconfig
      ARGOCD_HOST     = local.argo_host
      ARGOCD_PASSWORD = random_password.argo.result
    }
  }

  provisioner local-exec {
    command     = "${path.module}/scripts/bind-manager-argo-to-argo.sh"
    environment = {
      CONFIG   = var.argoconfig
      REVISION = local.revision
      SERVER   = local.argo_host
      HOST     = local.argo_host
      GITHUB_CLIENT_ID     = var.argo_github_client_id
      GITHUB_CLIENT_SECRET = var.argo_github_client_secret
    }
  }

  provisioner local-exec {
    when        = destroy
    command     = "${path.module}/scripts/uninstall-manager-argo.sh"
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
      ARGOCONFIG = self.triggers.argoconfig
    }
  }
}
