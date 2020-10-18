locals {
  argo_host      = "argo.${var.domain_name}"
  argo_namespace = "manager-argo"
}

resource random_password argo {
  length           = 12
  special          = true
  override_special = "!@#$%^&*()"
}

resource null_resource argo {
  depends_on = [
    null_resource.k3s_cluster,
    null_resource.kube_network,
  ]

  ## install manager-argo
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      export ENCPW=$(htpasswd -nbBC 10 "" "${random_password.argo.result}" | tr -d ':\n' | sed 's/$2y/$2a/')
      export MTIME=$(date -u +%FT%TZ)
      export GITHUB_ID=${var.argo_github_client_id}
      export GITHUB_SECRET=${var.argo_github_client_secret}
      helm --kubeconfig ${var.kubeconfig_path} \
           --namespace ${local.argo_namespace} \
           install manager-argo argo-cd \
           --create-namespace \
           --repo https://argoproj.github.io/argo-helm/ \
           --set fullnameOverride=manager-argo-argocd \
           --set server.config.url=http://${local.argo_host} \
           --set server.ingress.hosts[0]=${local.argo_host} \
           --set configs.secret.argocdServerAdminPassword=$${ENCPW} \
           --set configs.secret.argocdServerAdminPasswordMtime=$${MTIME} \
           --set configs.secret.extra."dex\.github\.clientID"=$${GITHUB_ID} \
           --set configs.secret.extra."dex\.github\.clientSecret"=$${GITHUB_SECRET} \
           --values ${path.module}/helm/argo-values.yaml \
           --version 2.9.3 \
           --wait
    EOC
  }
}
