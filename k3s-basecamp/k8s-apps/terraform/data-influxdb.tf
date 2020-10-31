locals {
  influxdb_namespace = "data-influxdb"
}

resource kubernetes_namespace influxdb {
  metadata {
    name = local.influxdb_namespace
  }
}

resource null_resource influxdb {
  depends_on = [
    kubernetes_namespace.influxdb,
    kubernetes_secret.influxdb_admin,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.influxdb.rendered
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

data template_file influxdb {
  # https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: data-influxdb
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/data-influxdb
        helm:
          parameters:
          - name:  influxdb.persistence.existingClaim
            value: ${kubernetes_persistent_volume_claim.influxdb.metadata[0].name}
          - name:  influxdb.ingress.hostname
            value: influxdb.${var.domain_name}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.influxdb_namespace}
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
##  Kubernetes persistent volume for InfluxDB
##

resource kubernetes_persistent_volume_claim influxdb {
  metadata {
    name = "influxdb-pvc"
    namespace = kubernetes_namespace.influxdb.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.influxdb_ebs_volume.size}Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.influxdb.metadata.0.name
    storage_class_name = "ebs-sc"
  }
  wait_until_bound = true
}

resource kubernetes_persistent_volume influxdb {
  metadata {
    name = "influxdb-pv"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "${var.influxdb_ebs_volume.size}Gi"
    }
    persistent_volume_source {
      aws_elastic_block_store {
        fs_type   = "ext4"
        volume_id = var.influxdb_ebs_volume.id
      }
    }
    storage_class_name = "ebs-sc"
  }
}


################################################################
##
##  Kubernetes secret for InfluxDB
##

resource kubernetes_secret influxdb_admin {
  depends_on = [
    kubernetes_namespace.influxdb,
  ]

  metadata {
    name = "influxdb-auth-secret"
    namespace = kubernetes_namespace.influxdb.metadata[0].name
  }

  data = {
    influxdb-user = "admin"
    influxdb-password = var.influxdb_admin_password
  }
}


