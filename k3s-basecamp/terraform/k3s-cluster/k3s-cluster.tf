resource null_resource k3s_cluster {
  depends_on = [
    aws_route53_record.wildcard_private,
    aws_route53_record.wildcard_public,
  ]

  provisioner remote-exec {
    connection {
      host        = aws_instance.basecamp.public_ip
      private_key = local.private_key
      type        = "ssh"
      user        = "ubuntu"
    }

    inline = [
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "export K3S_KUBECONFIG_MODE=400",
      "export INSTALL_K3S_EXEC=' --no-deploy servicelb --no-deploy traefik'",
      "curl -sfL https://get.k3s.io | sh -",
      "sudo chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml",
    ]
  }

  provisioner local-exec {
    command = <<EOC
${path.module}/scripts/download-k8s-context.sh \
    ${aws_instance.basecamp.public_ip} \
    ${var.public_key_path} \
    ${var.kubeconfig} \
    k3s.${var.domain_name}
EOC
  }
}
