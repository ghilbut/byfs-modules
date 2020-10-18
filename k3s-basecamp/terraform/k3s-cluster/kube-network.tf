locals {
  kube_network_namespace = "kube-network"
}

resource null_resource kube_network {
  depends_on = [
    null_resource.k3s_cluster,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
  }

  # metallb
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      helm --kubeconfig ${var.kubeconfig_path} \
           --namespace ${local.kube_network_namespace} \
           install metallb metallb \
           --create-namespace \
           --repo https://charts.bitnami.com/bitnami/ \
           --set fullnameOverride=kube-network-metallb \
           --set configInline.address-pools[0].name=default \
           --set configInline.address-pools[0].protocol=layer2 \
           --set configInline.address-pools[0].addresses=192.168.0.240-192.168.0.250 \
           --version 0.1.24 \
           --wait
    EOC
  }

  # ingress-nginx
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      export PRIVATE_IP=${aws_instance.master.private_ip}
      helm --kubeconfig ${var.kubeconfig_path} \
           --namespace ${local.kube_network_namespace} \
           install ingress-nginx ingress-nginx \
           --create-namespace \
           --repo https://kubernetes.github.io/ingress-nginx/ \
           --set fullnameOverride=kube-network-ingress-nginx \
           --set controller.service.externalIPs[0]=$${PRIVATE_IP} \
           --version 3.7.1 \
           --wait
    EOC
  }

  # cert-manager
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      helm --kubeconfig ${var.kubeconfig_path} \
           --namespace ${local.kube_network_namespace} \
           install cert-manager cert-manager \
           --create-namespace \
           --repo https://charts.jetstack.io \
           --set fullnameOverride=kube-network-cert-manager \
           --set installCRDs=true \
           --version v1.0.2 \
           --wait
    EOC
  }

  # cert-manager cluster-issuer
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      export PRIVATE_IP=${aws_instance.master.private_ip}
      kubectl --kubeconfig ${var.kubeconfig_path} \
              --namespace ${local.kube_network_namespace} \
              apply -f - <<EOF
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt
      spec:
        acme:
          email: ghilbut@gmail.com
          server: https://acme-v02.api.letsencrypt.org/directory
          privateKeySecretRef:
            name: letsencrypt
          solvers:
          - http01:
              ingress:
                class: nginx
      EOF
    EOC
  }
}
