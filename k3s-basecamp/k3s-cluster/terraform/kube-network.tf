locals {
  kube_network_namespace = "kube-network"
}

resource helm_release metallb {
  name       = "metallb"
  chart      = "metallb"
  repository = "https://charts.bitnami.com/bitnami/"
  version    = "0.1.24"
  namespace  = local.kube_network_namespace

  set {
    name  = "fullnameOverride"
    value = "kube-network-metallb"
  }

  set {
    name  = "configInline.address-pools[0].name"
    value = "default"
  }

  set {
    name  = "configInline.address-pools[0].protocol"
    value = "layer2"
  }

  set {
    name  = "configInline.address-pools[0].addresses"
    value = "192.168.0.240-192.168.0.250"
  }

  create_namespace = true
}

resource helm_release ingress_nginx {
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx/"
  version    = "3.7.1"
  namespace  = local.kube_network_namespace

  set {
    name  = "fullnameOverride"
    value = "kube-network-ingress-nginx"
  }

  set {
    name  = "controller.service.externalIPs[0]"
    value = aws_instance.master.private_ip
  }

  create_namespace = true
}

resource helm_release cert_manager {
  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.0.2"
  namespace  = local.kube_network_namespace

  set {
    name  = "fullnameOverride"
    value = "kube-network-cert-manager"
  }

  set {
    name  = "installCRDs"
    value = true
  }

  create_namespace = true
}

resource null_resource cert_manager_cluster_issuer {
  depends_on = [
    helm_release.cert_manager,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
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
