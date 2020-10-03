resource null_resource k8s_network {
  depends_on = [
    null_resource.k3s_cluster,
  ]
  triggers = {
    kubeconfig = var.kubeconfig
    script     = md5(file("${path.module}/scripts/install-k8s-network.sh"))
    uninstall  = "${path.module}/scripts/uninstall-k8s-network.sh"
  }

  provisioner local-exec {
    command = <<EOC
${path.module}/scripts/install-k8s-network.sh \
    ${var.kubeconfig} \
    ${local.helmchart_path}/k8s-network/ \
    ${local.helmchart_path}/k8s-network-issuers/ \
    ${aws_instance.basecamp.private_ip}
EOC
  }

  provisioner local-exec {
    when        = destroy
    command     = "${path.module}/scripts/uninstall-k8s-network.sh"
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}
