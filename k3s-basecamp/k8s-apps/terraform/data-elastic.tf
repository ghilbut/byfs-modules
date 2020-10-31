locals {
  elastic_namespace = "data-elastic"
}

resource kubernetes_namespace elastic {
  metadata {
    name = local.elastic_namespace
  }
}

resource null_resource elastic {
  depends_on = [
    kubernetes_namespace.elastic,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.elastic.rendered
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

data template_file elastic {
  # https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: data-elastic
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/data-elastic
        helm:
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.elastic_namespace}
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
##  Kubernetes Persistent Volume
##

resource kubernetes_persistent_volume_claim elasticsearch {
  metadata {
    # name: volumeclaimtemplates-name-statefulset-name-replica-index
    name = "elasticsearch-elasticsearch-0"
    namespace = kubernetes_namespace.elastic.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.elasticsearch_ebs_volume.size}Gi"
      }
    }
    storage_class_name = "ebs-sc"
    volume_name = kubernetes_persistent_volume.elasticsearch.metadata[0].name
  }
}

resource kubernetes_persistent_volume elasticsearch {
  metadata {
    name = "elasticsearch-0"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "${var.elasticsearch_ebs_volume.size}Gi"
    }
    persistent_volume_source {
      aws_elastic_block_store {
        fs_type   = "ext4"
        volume_id = var.elasticsearch_ebs_volume.id
      }
    }
    storage_class_name = "ebs-sc"
  }
}
