locals {
  kibana_namespace = "observer-kibana"
}

resource kubernetes_namespace kibana {
  metadata {
    name = local.kibana_namespace
  }
}

resource null_resource kibana {
  depends_on = [
    kubernetes_namespace.kibana,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.kibana.rendered
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

data template_file kibana {
  # https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: observer-kibana
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/observer-kibana
        helm:
          parameters:
          - name:  oauth2-poxy.extraEnv[0].value
            value: "${var.github_orgs[0]}"
          - name:  oauth2-proxy.ingress.hosts[0]
            value: kibana.${var.domain_name}
          - name:  oauth2-proxy.ingress.tls[0].hosts[0]
            value: kibana.${var.domain_name}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.kibana_namespace}
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
##  Kubernetes ConfigMap and Secret
##

resource random_string kibana_oauth2_cookie_secret {
  length = 32
  upper = false
  special = false
}

resource kubernetes_secret kibana_oauth2 {
  metadata {
    name = "kibana-oauth2-secret"
    namespace = kubernetes_namespace.kibana.metadata[0].name
  }

  data = {
    client-id = var.kibana_github_client.id
    client-secret = var.kibana_github_client.secret
    cookie-secret = random_string.kibana_oauth2_cookie_secret.result
  }
}
