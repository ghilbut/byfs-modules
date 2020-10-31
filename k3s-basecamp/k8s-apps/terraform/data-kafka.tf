locals {
  kafka_namespace = "data-kafka"
}

resource kubernetes_namespace kafka {
  metadata {
    name = local.kafka_namespace
  }
}

resource null_resource kafka {
  depends_on = [
    kubernetes_namespace.kafka,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.kafka.rendered
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

data template_file kafka {
  # https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: data-kafka
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/data-kafka
        helm:
          parameters:
          - name:  kafka.cp-zookeeper.persistence.dataDirSize
            value: ${var.zookeeper_ebs_volumes.data.size}Gi
          - name:  kafka.cp-zookeeper.persistence.dataLogDirSize
            value: ${var.zookeeper_ebs_volumes.log.size}Gi
          - name:  kafka.cp-kafka.persistence.size
            value: ${var.kafka_ebs_volume.size}Gi
          - name:  oauth2-poxy.extraEnv[0].value
            value: "${var.github_orgs[0]}"
          - name:  oauth2-proxy.ingress.hosts[0]
            value: kafka.${var.domain_name}
          - name:  oauth2-proxy.ingress.tls[0].hosts[0]
            value: kafka.${var.domain_name}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.kafka_namespace}
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

resource random_string kafka_oauth2_cookie_secret {
  length = 32
  upper = false
  special = false
}

resource kubernetes_secret kafka_oauth2 {
  metadata {
    name = "kafka-oauth2-secret"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }

  data = {
    client-id = var.kafka_github_client.id
    client-secret = var.kafka_github_client.secret
    cookie-secret = random_string.kafka_oauth2_cookie_secret.result
  }
}


################################################################
##
##  Kubernetes Persistent Volumes
##

##--------------------------------------------------------------
##  persistent volume claims

resource kubernetes_persistent_volume_claim zookeeper {
  metadata {
    # name: volumeclaimtemplates-name-statefulset-name-replica-index
    name = "datadir-data-kafka-cp-zookeeper-0"
    namespace = kubernetes_namespace.kafka.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.zookeeper_ebs_volumes.data.size}Gi"
      }
    }
    storage_class_name = "ebs-sc"
    volume_name = kubernetes_persistent_volume.zookeeper.metadata[0].name
  }
}

resource kubernetes_persistent_volume_claim zookeeper_log {
  metadata {
    # name: volumeclaimtemplates-name-statefulset-name-replica-index
    name = "datalogdir-data-kafka-cp-zookeeper-0"
    namespace = kubernetes_namespace.kafka.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.zookeeper_ebs_volumes.log.size}Gi"
      }
    }
    storage_class_name = "ebs-sc"
    volume_name = kubernetes_persistent_volume.zookeeper_log.metadata[0].name
  }
}

resource kubernetes_persistent_volume_claim kafka {
  metadata {
    # name: volumeclaimtemplates-name-statefulset-name-replica-index
    name = "datadir-0-data-kafka-cp-kafka-0"
    namespace = kubernetes_namespace.kafka.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.kafka_ebs_volume.size}Gi"
      }
    }
    storage_class_name = "ebs-sc"
    volume_name = kubernetes_persistent_volume.kafka.metadata[0].name
  }
}

##--------------------------------------------------------------
##  persistent volumes

resource kubernetes_persistent_volume zookeeper {
  metadata {
    name = "data-zookeeper-0"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "${var.zookeeper_ebs_volumes.data.size}Gi"
    }
    persistent_volume_source {
      aws_elastic_block_store {
        fs_type   = "ext4"
        volume_id = var.zookeeper_ebs_volumes.data.id
      }
    }
    storage_class_name = "ebs-sc"
  }
}

resource kubernetes_persistent_volume zookeeper_log {
  metadata {
    name = "data-zookeeper-log-0"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "${var.zookeeper_ebs_volumes.log.size}Gi"
    }
    persistent_volume_source {
      aws_elastic_block_store {
        fs_type   = "ext4"
        volume_id = var.zookeeper_ebs_volumes.log.id
      }
    }
    storage_class_name = "ebs-sc"
  }
}

resource kubernetes_persistent_volume kafka {
  metadata {
    name = "data-kafka-0-0"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "${var.kafka_ebs_volume.size}Gi"
    }
    persistent_volume_source {
      aws_elastic_block_store {
        fs_type   = "ext4"
        volume_id = var.kafka_ebs_volume.id
      }
    }
    storage_class_name = "ebs-sc"
  }
}
