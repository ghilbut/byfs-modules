locals {
  drone_host      = "drone.${var.domain_name}"
  drone_namespace = "manager-drone"
}

resource kubernetes_namespace drone {
  metadata {
    name = local.drone_namespace
  }
}

resource null_resource drone {
  depends_on = [
    null_resource.argo,
    kubernetes_secret.drone_server_secret,
    kubernetes_secret.drone_runner_secret,
    mysql_database.drone,
    mysql_user.drone,
    mysql_grant.drone,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.drone.rendered
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

data template_file drone {
  ## NOTE(ghilbut.kim): https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: manager-drone
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/manager-drone
        helm:
          parameters:
          - name:  server.ingress.hosts[0].host
            value: ${local.drone_host}
          - name:  server.env.DRONE_REPOSITORY_FILTER
            value: ${var.drone_repository_filter}
          - name:  server.env.DRONE_SERVER_PROXY_HOST
            value: ${local.drone_host}
          - name:  secrets.env.SECRET_KEY
            value: x
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.drone_namespace}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - Validate=true
    EOF
  EOT
}


################################################################
##
##  Kubernetes secrets for Drone CI
##

resource random_string drone_rpc_secret {
  length  = 32
  upper   = false
  special = false
}

resource random_string drone_secrets_plugin_token {
  length  = 32
  upper   = false
  special = false
}

resource kubernetes_secret drone_server_secret {
  depends_on = [
    kubernetes_namespace.drone,
  ]

  metadata {
    name      = "drone-server-secret"
    namespace = local.drone_namespace
  }

  data = {
    DRONE_DATABASE_DATASOURCE  = local.drone_datasource
    DRONE_GITHUB_CLIENT_ID     = var.drone_github_client.id
    DRONE_GITHUB_CLIENT_SECRET = var.drone_github_client.secret
    DRONE_RPC_SECRET           = random_string.drone_rpc_secret.result
  }
}

resource kubernetes_secret drone_runner_secret {
  depends_on = [
    kubernetes_namespace.drone,
  ]

  metadata {
    name      = "drone-runner-secret"
    namespace = local.drone_namespace
  }

  data = {
    DRONE_RPC_SECRET           = random_string.drone_rpc_secret.result
    DRONE_SECRET_PLUGIN_TOKEN  = random_string.drone_secrets_plugin_token.result
  }
}

resource kubernetes_secret drone_secret_plugin_secret {
  depends_on = [
    kubernetes_namespace.drone,
  ]

  metadata {
    name      = "drone-secrets-plugin-secret"
    namespace = local.drone_namespace
  }

  data = {
    SECRET_KEY = random_string.drone_secrets_plugin_token.result
  }
}


################################################################
##
##  MySQL for Drone CI
##

locals {
  drone_database = "drone"
  drone_username = "drone"
  drone_datasource = data.template_file.drone_datasource.rendered
}

data template_file drone_datasource {
  template = "$${username}:$${password}@tcp($${host}:$${port})/$${database}"
  vars = {
    host = var.mysql_host
    port = var.mysql_port
    database = local.drone_database
    username = local.drone_username
    password = var.drone_mysql_password
  }
}

resource mysql_database drone {
  name = local.drone_database
}

resource mysql_user drone {
  user = local.drone_username
  host = "%"
  plaintext_password = var.drone_mysql_password
}

resource mysql_grant drone {
  user       = mysql_user.drone.user
  host       = mysql_user.drone.host
  database   = local.drone_database
  privileges = ["ALL"]
}
