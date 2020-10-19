
resource kubernetes_persistent_volume influxdb {
  metadata {
    name = "influxdb-pv"
  }
  spec {
    capacity = {
      storage = "${var.ebs_influxdb_size}Gi"
    }
    access_modes = ["ReadWriteOnce"]
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
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.ebs_influxdb_size}Gi"
      }
    }
    volume_name = "${kubernetes_persistent_volume.influxdb.metadata.0.name}"
  }
}
