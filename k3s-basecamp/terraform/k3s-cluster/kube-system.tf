resource null_resource kube_system {
  depends_on = [
    null_resource.manager_argo
  ]
  triggers = {
    argoconfig = var.argoconfig
    kubeconfig = var.kubeconfig
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
    command = <<-EOC
      #!/bin/sh -eux
      argocd --config ${var.argoconfig} \
             --grpc-web \
             --insecure \
             app create kube-system \
             --auto-prune \
             --dest-namespace kube-system \
             --dest-server https://kubernetes.default.svc \
             --path k3s-basecamp/helm/kube-system \
             --project default \
             --repo https://github.com/ghilbut/byfs-modules.git \
             --revision ${local.revision} \
             --self-heal \
             --sync-option Prune=true \
             --sync-policy automated
    EOC
  }

  provisioner local-exec {
    when    = destroy
    command = <<-EOC
      #!/bin/sh -eux
      argocd --config ${self.triggers.argoconfig} \
             --grpc-web \
             --insecure \
             app delete kube-system
      kubectl --kubeconfig ${self.triggers.kubeconfig} \
              --namespace kube-system \
              delete configmap aws-auth
    EOC
  }
}
