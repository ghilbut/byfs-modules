resource null_resource manager_drone {

  provisioner local-exec {
    command = <<-EOC
      #!/bin/sh -eux
      argocd --config ${var.argoconfig} \
             --grpc-web \
             --insecure \
             app create manager-drone \
             --auto-prune \
             --create-namespace \
             --dest-namespace manager-drone \
             --dest-server https://kubernetes.default.svc \
             --helm-set server.ingress.hosts[0].host="drone.ghilbut.com" \
             --helm-set server.env.DRONE_GITHUB_CLIENT_ID=bf3589b369b96b5a4fbc \
             --helm-set server.env.DRONE_GITHUB_CLIENT_SECRET=b079aba668617453d5d7f08ae0b0b1bd0b302cfe \
             --path k3s-basecamp/helm/manager-drone \
             --project default \
             --repo https://github.com/ghilbut/byfs-modules.git \
             --revision ${var.revision} \
             --self-heal \
             --sync-option Prune=true \
             --sync-policy automated
    EOC
  }

  provisioner local-exec {
    command = <<-EOC

    EOC
  }
}
