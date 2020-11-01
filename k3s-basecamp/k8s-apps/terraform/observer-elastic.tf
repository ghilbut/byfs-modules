locals {
  beats_namespace = "observer-beats"
}

resource kubernetes_namespace beats {
  metadata {
    name = local.beats_namespace
  }
}

resource null_resource beats {
  depends_on = [
    kubernetes_namespace.beats,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.beats.rendered
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

data template_file beats {
  # https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: observer-beats
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/observer-beats
        helm:
          parameters:
          - name:  apm-server.ingress.hosts[0]
            value: apm.${var.domain_name}
          - name:  apm-server.ingress.tls[0].hosts[0]
            value: apm.${var.domain_name}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.beats_namespace}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - Validate=true
    EOF
  EOT
}
