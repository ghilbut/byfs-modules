resource random_password argo {
  length           = 12
  special          = true
  override_special = "!@#$%^&*()"
}

resource null_resource manager_argo {
  depends_on = [
    null_resource.k8s_network,
  ]
  triggers = {
    kubeconfig = var.kubeconfig
    argoconfig = var.argoconfig
  }

  # install manager-argo
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      export ENCPW=$(htpasswd -nbBC 10 "" "${random_password.argo.result}" | tr -d ':\n' | sed 's/$2y/$2a/')
      export MTIME=$(date -u +%FT%TZ)
      export GITHUB_ID=${var.argo_github_client_id}
      export GITHUB_SECRET=${var.argo_github_client_secret}
      helm --kubeconfig ${var.kubeconfig} \
           --namespace manager-argo \
           install manager-argo ${local.helmchart_path}/manager-argo/ \
           --create-namespace \
           --dependency-update \
           --set cd.server.config.url=http://${local.argo_host} \
           --set cd.server.ingress.hosts[0]=${local.argo_host} \
           --set cd.configs.secret.argocdServerAdminPassword=$${ENCPW} \
           --set cd.configs.secret.argocdServerAdminPasswordMtime=$${MTIME} \
           --set cd.configs.secret.extra."dex\.github\.clientID"=$${GITHUB_ID} \
           --set cd.configs.secret.extra."dex\.github\.clientSecret"=$${GITHUB_SECRET} \
           --wait
      #     --set cd.server.ingress.tls[0].hosts[0]=${local.argo_host} \
    EOC
  }

  # wait until accessable
  provisioner local-exec {
    command = <<-EOF
      while [[ "$(curl -s -o /dev/null -L -w %%{http_code} http://${local.argo_host})" != "200" ]]
      do
        echo 'Waiting "${local.argo_host}" online'
        sleep 5
      done
    EOF
  }

  # login to get context
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      mkdir ${dirname(var.argoconfig)}
      argocd --config ${var.argoconfig} \
             --grpc-web \
             --insecure \
             login ${local.argo_host} \
             --name k3s-basecamp \
             --username admin \
             --password "${random_password.argo.result}"
    EOC
  }

  # bind manager-argo to itself
  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      argocd --config ${var.argoconfig} \
             --grpc-web \
             --insecure \
             app create manager-argo \
             --dest-namespace manager-argo \
             --dest-server https://kubernetes.default.svc \
             --path k3s-basecamp/helm/manager-argo \
             --project default \
             --repo https://github.com/ghilbut/byfs-modules.git \
             --revision ${local.revision} \
             --helm-set-string cd.server.config.url=http://${local.argo_host} \
             --helm-set-string cd.server.ingress.hosts[0]=${local.argo_host} \
             --sync-option Prune=true
      #     --set cd.server.ingress.tls[0].hosts[0]=${local.argo_host} \
    EOC
  }

  # remove manager-argo when destroy
  provisioner local-exec {
    when    = destroy
    command = <<-EOC
      #!/bin/sh -eux
      argocd --config ${self.triggers.argoconfig} \
             --grpc-web \
             --insecure \
             app delete manager-argo
      helm --kubeconfig ${self.triggers.kubeconfig} \
           --namespace manager-argo \
           uninstall manager-argo
      rm -rf ${dirname(self.triggers.argoconfig)}
    EOC
  }
}
