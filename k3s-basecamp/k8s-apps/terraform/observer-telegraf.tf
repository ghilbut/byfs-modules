locals {
  telegraf_namespace = "observer-telegraf"
}

resource kubernetes_namespace telegraf {
  metadata {
    name = local.telegraf_namespace
  }
}

resource null_resource telegraf {
  depends_on = [
    kubernetes_namespace.telegraf,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.telegraf.rendered
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

data template_file telegraf {
  # https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: observer-telegraf
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/observer-telegraf
        helm:
          parameters:
          - name:  consumer.config.outputs[0].influxdb.username
            value: admin
          - name:  consumer.config.outputs[0].influxdb.password
            value: "${var.influxdb_admin_password}"
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.telegraf_namespace}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - Validate=true
      ignoreDifferences:
      - group: rbac.authorization.k8s.io
        jsonPointers:
        - /rules
        kind: ClusterRole
        name: influx:telegraf
    EOF
  EOT
}
