locals {
  kube_network_namespace = "kube-network"
}

resource null_resource kube_network {
  depends_on = [
    null_resource.argo,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.kube_network.rendered
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

data template_file kube_network {
  ## https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: kube-network
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/helm/kube-network
        helm:
          parameters:
          - name:  ingress-nginx.controller.service.externalIPs[0]
            value: ${var.ingress_ip}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.kube_network_namespace}
      syncPolicy:
        #automated:
        #  prune: true
        #  selfHeal: true
        syncOptions:
        - Validate=true
        - CreateNamespace=true
    EOF
  EOT
}

resource null_resource kube_network_issuers {
  count = 0

  depends_on = [
    null_resource.kube_network,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.kube_network_issuers.rendered
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

data template_file kube_network_issuers {
  ## https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: kube-network-issuers
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/helm/kube-network-issuers
        helm:
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.kube_network_namespace}
      syncPolicy:
        #automated:
        #  prune: true
        #  selfHeal: true
        syncOptions:
        - Validate=true
        - CreateNamespace=true
    EOF
  EOT
}
