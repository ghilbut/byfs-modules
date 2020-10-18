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
      export INSTALL_K3S_EXEC='
         --disable-cloud-controller
         --kube-apiserver-arg cloud-provider=external
         --kube-apiserver-arg allow-privileged=true
         --kube-apiserver-arg feature-gates=CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true,VolumeSnapshotDataSource=true
         --kube-controller-arg cloud-provider=external
         --kubelet-arg feature-gates=CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true
         --no-deploy local-storage
         --no-deploy servicelb
         --no-deploy traefik
         --token ${random_uuid.token.result}'
      curl -sfL https://get.k3s.io | sh -
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

provider kubernetes {
  config_path = var.kubeconfig_path
}
