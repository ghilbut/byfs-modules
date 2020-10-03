resource random_uuid token {
}

resource null_resource k3s_cluster {
  depends_on = [
    aws_route53_record.wildcard_private,
    aws_route53_record.wildcard_public,
  ]

  provisioner file {
    connection {
      host        = aws_instance.basecamp.public_ip
      private_key = local.private_key
      type        = "ssh"
      user        = "ubuntu"
    }

    source      = "${path.module}/scripts/install-k3s-cluster.sh"
    destination = "/home/ubuntu/install-k3s-cluster.sh"
  }

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
      "TOKEN=${random_uuid.token.result} sh /home/ubuntu/install-k3s-cluster.sh",
    ]
  }

  provisioner local-exec {
    command = <<-EOC
      ${path.module}/scripts/download-k8s-context.sh \
        ${aws_instance.basecamp.public_ip} \
        ${var.public_key_path} \
        ${var.kubeconfig} \
        k3s.${var.domain_name}
    EOC
  }
}
