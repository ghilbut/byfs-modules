resource random_uuid token {
}

resource null_resource k3s_cluster {
  depends_on = [
    aws_route53_record.wildcard_private,
    aws_route53_record.wildcard_public,
  ]

  # upload install script
  provisioner file {
    connection {
      host        = aws_instance.master.public_ip
      private_key = file(var.private_key_path)
      type        = "ssh"
      user        = "ubuntu"
    }

    content = <<-EOC
      #!/bin/sh -eux
      export K3S_KUBECONFIG_MODE=400
      #export INSTALL_K3S_EXEC='
      #   --disable-cloud-controller
      #   --disable local-storage
      #   --disable servicelb
      #   --disable traefik
      #   --kube-apiserver-arg allow-privileged=true
      #   --kube-apiserver-arg cloud-provider=external
      #   --kube-apiserver-arg feature-gates=CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true,VolumeSnapshotDataSource=true
      #   --kube-controller-arg cloud-provider=external
      #   --kubelet-arg cloud-provider=external
      #   --kubelet-arg feature-gates=CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true
      #   --kubelet-arg provider-id="aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
      #   --token ${random_uuid.token.result}'
      curl https://releases.rancher.com/install-docker/19.03.sh | sh
      curl -sfL https://get.k3s.io | sh -s - server \
           --disable-cloud-controller \
           --disable local-storage \
           --disable servicelb \
           --disable traefik \
           --docker \
           --kube-apiserver-arg allow-privileged=true \
           --kube-apiserver-arg cloud-provider=external \
           --kube-apiserver-arg feature-gates=CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true,VolumeSnapshotDataSource=true,CSIMigration=true,CSIMigrationAWS=true \
           --kube-controller-arg cloud-provider=external \
           --kubelet-arg feature-gates=CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true,CSIMigration=true,CSIMigrationAWS=true \
           --token ${random_uuid.token.result}
      sudo chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml
    EOC
    destination = "/home/ubuntu/install-k3s-cluster.sh"
  }

  # install k3s server
  provisioner remote-exec {
    connection {
      host        = aws_instance.master.public_ip
      private_key = file(var.private_key_path)
      type        = "ssh"
      user        = "ubuntu"
    }

    inline = [
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sh /home/ubuntu/install-k3s-cluster.sh",
    ]
  }

  # download kubernetes context file
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      rm -rf ${dirname(var.kubeconfig_path)}
      mkdir -p ${dirname(var.kubeconfig_path)}
      scp -i ${var.private_key_path} \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -q \
          ubuntu@${aws_instance.master.public_ip}:/etc/rancher/k3s/k3s.yaml \
          ${dirname(var.kubeconfig_path)}
      sed -i -e "s/127\.0\.0\.1/${local.k3s_host}/g" ${var.kubeconfig_path}
    EOC
  }
}

data external kubeconfig_path {
  depends_on = [
    null_resource.k3s_cluster,
  ]

  program = [
    "echo",
    "{ \"path\": \"${var.kubeconfig_path}\" }",
  ]
}

provider kubernetes {
  config_path = data.external.kubeconfig_path.result.path
}

provider helm {
  kubernetes {
    config_path = data.external.kubeconfig_path.result.path
  }
}
