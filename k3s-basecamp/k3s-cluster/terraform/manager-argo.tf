locals {
  argo_host      = "argo.${var.domain_name}"
  argo_namespace = "manager-argo"
}

resource kubernetes_namespace argo {
  depends_on = [
    null_resource.k3s_cluster,
  ]

  metadata {
    name = local.argo_namespace
  }
}

data external argo {
  depends_on = [
    null_resource.k3s_cluster,
  ]

  program = [
    "${path.module}/scripts/argo.sh",
    var.argo_admin_password,
  ]
}

resource helm_release argo {
  lifecycle {
    ignore_changes = [
        set,
        set_sensitive,
    ]
  }

  name       = "manager-argo"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm/"
  version    = "2.9.3"
  namespace  = kubernetes_namespace.argo.metadata[0].name

  values = [
    file("${path.module}/helm-values/argo.yaml"),
  ]

  set {
    name  = "fullnameOverride"
    value = "manager-argo-argocd"
  }

  set {
    name  = "server.config.url"
    value = "http://${local.argo_host}"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = local.argo_host
  }

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = data.external.argo.result.encpw
  }

  set {
    name  = "configs.secret.argocdServerAdminPasswordMtime"
    value = data.external.argo.result.mtime
  }

  set_sensitive {
    name  = "configs.secret.extra.dex\\.github\\.clientID"
    value = var.argo_github_client_id
  }

  set_sensitive {
    name  = "configs.secret.extra.dex\\.github\\.clientSecret"
    value = var.argo_github_client_secret
  }

  set_sensitive {
    name  = "configs.secret.extra.dex\\.github\\.org"
    value = var.argo_github_org
  }
}
