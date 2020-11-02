locals {
  argo_host      = "argo.${var.domain_name}"
  argo_namespace = "manager-argo"
}

resource null_resource argo {
  triggers = {
    kubeconfig_path = var.kubeconfig_path
    definition = data.template_file.argo.rendered
  }

  provisioner local-exec {
    command = self.triggers.definition
    environment = {
      METHOD = "apply"
    }
  }

  provisioner local-exec {
    when    = destroy
    command = self.triggers.definition
    environment = {
      METHOD = "delete"
    }
  }
}

data template_file argo {
  ## https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: manager-argo
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/manager-argo
        helm:
          parameters:
          - name:  argo-cd.server.ingress.hosts[0]
            value: ${local.argo_host}
          - name:  argo-cd.server.ingress.tls[0].hosts[0]
            value: ${local.argo_host}
          - name:  argo-cd.server.config.url
            value: https://${local.argo_host}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.argo_namespace}
      syncPolicy:
        syncOptions:
        - Validate=true
    EOF
  EOT
}
