locals {
  grafana_database  = "grafana"
  grafana_username  = "grafana"
  grafana_namespace = "observer-grafana"
}


resource mysql_database grafana {
  name                  = local.grafana_database
  default_character_set = "utf8mb4"
  default_collation     = "utf8mb4_unicode_ci"
}

resource random_password grafana_mysql {
  length = 16
  special = true
  override_special = "‘~!@#$%^&*()_-+={}[]/<>,.;?':|"
}

resource mysql_user grafana {
  user               = local.grafana_username
  host               = "%"
  plaintext_password = random_password.grafana_mysql.result
}

resource mysql_grant grafana {
  user       = mysql_user.grafana.user
  host       = mysql_user.grafana.host
  database   = mysql_database.grafana.name
  privileges = ["ALL"]
}


resource kubernetes_namespace grafana {
  metadata {
    name = local.grafana_namespace
  }
}

resource random_password grafana_admin {
  length           = 12
  special          = true
  override_special = "!@#$%^&*()"
}

resource kubernetes_secret grafana_admin_secret {
  depends_on = [
    kubernetes_namespace.grafana,
  ]

  metadata {
    name      = "grafana-admin-secret"
    namespace = local.grafana_namespace
  }

  data = {
    username = local.grafana_username
    password = random_password.grafana_admin.result
  }

  type = "kubernetes.io/basic-auth"
}

resource kubernetes_secret grafana_secret {
  depends_on = [
    kubernetes_namespace.grafana,
  ]

  metadata {
    name      = "grafana-secret"
    namespace = local.grafana_namespace
  }

  data = {
    GF_AUTH_GITHUB_CLIENT_ID     = var.github_clients.grafana.id
    GF_AUTH_GITHUB_CLIENT_SECRET = var.github_clients.grafana.secret
    GF_DATABASE_USER             = local.grafana_username
    GF_DATABASE_PASSWORD         = random_password.grafana_mysql.result
  }
}

resource null_resource grafana {
  depends_on = [
    kubernetes_secret.grafana_admin_secret,
    kubernetes_secret.grafana_secret,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.grafana.rendered
  }

  provisioner local-exec {
    command = self.triggers.sync
    environment = {
      METHOD = "apply"
    }
  }

  provisioner local-exec {
    when    = destroy
    command = self.triggers.sync
    environment = {
      METHOD = "delete"
    }
  }
}

data template_file grafana {
  # https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: observer-grafana
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/observer-grafana
        helm:
          parameters:
          - name:  grafana.ingress.hosts[0]
            value: grafana.${var.domain_name}
          - name:  grafana.grafana\\.ini.server.protocol
            value: http
          - name:  grafana.grafana\\.ini.server.root_url
            value: http://grafana.${var.domain_name}
          - name:  grafana.grafana\\.ini.database.host
            value: ${var.mysql_host}:${var.mysql_port}
          - name:  grafana.grafana\\.ini.database.name
            value: ${local.grafana_database}
          - name:  grafana.grafana\\.ini.auth\\.github.allowed_organizations
            value: ${join(",", var.github_orgs)}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.grafana_namespace}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - Validate=true
    EOF
  EOT
}
