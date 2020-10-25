/*
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
    kubernetes_persistent_volume.influxdb,
    kubernetes_persistent_volume_claim.influxdb,
    kubernetes_secret.influxdb,
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
          - name:  influxdb.persistence.size
            value: ${var.ebs_influxdb_size}Gi
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

resource kubernetes_persistent_volume influxdb {
  metadata {
    name = "influxdb-pv"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "${var.ebs_influxdb_size}Gi"
    }
    persistent_volume_source {
      aws_elastic_block_store {
        fs_type   = "ext4"
        volume_id = var.ebs_influxdb_id
      }
    }
  }
}

resource kubernetes_persistent_volume_claim influxdb {
  metadata {
    name = "influxdb-pvc"
    namespace = kubernetes_namespace.influxdb.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.ebs_influxdb_size}Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.influxdb.metadata.0.name
  }
  wait_until_bound = true
}


################################################################
##
##  Kubernetes secret for InfluxDB
##

resource random_password influxdb_admin {
  length = 16
  special = true
  override_special = "‘~!@#$%^&*()_-+={}[]/<>,.;?':|"
}

resource kubernetes_secret influxdb {
  metadata {
    name = "influxdb-auth-secret"
    namespace = kubernetes_namespace.influxdb.metadata[0].name
  }

  data = {
    influxdb-user = "admin"
    influxdb-password = random_password.influxdb_admin.result
  }
}
*/
