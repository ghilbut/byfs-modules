resource null_resource k8s_network {
  depends_on = [
    null_resource.k3s_cluster,
  ]
  triggers = {
    kubeconfig = var.kubeconfig
  }

  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      export CHART_PATH=${local.helmchart_path}/k8s-network/
      export PRIVATE_IP=${aws_instance.master.private_ip}
      helm dependency update $CHART_PATH
      helm --kubeconfig ${var.kubeconfig} \
           --namespace k8s-network \
           install k8s-network $CHART_PATH \
           --create-namespace \
           --dependency-update \
           --set ingress-nginx.controller.service.externalIPs[0]=$${PRIVATE_IP} \
           --wait
    EOC
  }

  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      helm --kubeconfig ${var.kubeconfig} \
           --namespace k8s-network \
           install k8s-network-issuers ${local.helmchart_path}/k8s-network-issuers/ \
           --wait
    EOC
  }

  provisioner local-exec {
    when    = destroy
    command = <<-EOC
      #!/bin/sh -eux
      helm --kubeconfig ${self.triggers.kubeconfig} \
           --namespace k8s-network \
           uninstall k8s-network
      kubectl --kubeconfig ${self.triggers.kubeconfig} \
              delete namespace k8s-network
    EOC
  }
}
