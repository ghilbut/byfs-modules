locals {
  dashboard_host           = "k3s.${var.domain_name}"
  kube_system_namespace = "kube-system"
}

resource null_resource kube_system {
  depends_on = [
    null_resource.argo,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.kube_system.rendered
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

data template_file kube_system {
  ## https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: kube-system
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/kube-system
        helm:
          parameters:
          - name:  dashboard.ingress.hosts[0]
            value: ${local.dashboard_host}
          - name:  dashboard.ingress.tls[0].hosts[0]
            value: ${local.dashboard_host}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.kube_system_namespace}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - Validate=true
        - CreateNamespace=true
    EOF
  EOT
}
