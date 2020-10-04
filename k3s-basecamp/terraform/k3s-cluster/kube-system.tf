resource null_resource kube_system2 {
  depends_on = [
    null_resource.k3s_cluster,
  ]
  triggers = {
    scripts = md5("${path.module}/scripts/install-kube-system-by-argo.sh"),
  }

  provisioner local-exec {
    command = <<-EOC
      kubectl --kubeconfig ${var.kubeconfig} \
              --namespace kube-system \
              apply -f - <<EOF
      ---
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: aws-auth
        namespace: kube-system
      data:
        mapRoles: |
          - rolearn: ${aws_iam_role.basecamp.arn}
            username: system:node:${aws_instance.basecamp.private_dns}
            groups:
            - system:bootstrappers
            - system:nodes
      EOF
    EOC
  }

  provisioner local-exec {
    command     = "${path.module}/scripts/install-kube-system-by-argo.sh"
    environment = {
      CONFIG   = var.argoconfig
      REVISION = "featrue/k3s-basecamp-terraform"
      #REVISION = local.revision
      ROLE_ARN = aws_iam_role.basecamp.arn
      EC2_PRIVATE_DNS_NAME = aws_instance.basecamp.private_dns
    }
  }

}
