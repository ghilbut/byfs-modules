locals {
  docker_namespace = "data-docker"
}

resource kubernetes_namespace docker {
  metadata {
    name = local.docker_namespace
  }
}

resource null_resource docker {
  depends_on = [
    kubernetes_namespace.docker,
  ]
  triggers = {
    kubeconfig = var.kubeconfig_path
    sync = data.template_file.docker.rendered
  }

  provisioner local-exec {
    command = self.triggers.sync
    environment = {
      METHOD = "apply"
    }
  }

  provisioner local-exec {
    when    = destroy
    command = self.triggers.sync
    environment = {
      METHOD = "delete"
    }
  }
}

data template_file docker {
  # https://argoproj.github.io/argo-cd/operator-manual/application.yaml
  template = <<-EOT
    kubectl --kubeconfig ${var.kubeconfig_path} $METHOD -f - <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: data-docker
      namespace: ${local.argo_namespace}
    spec:
      project: default
      source:
        repoURL: ${var.helmchart_url}
        targetRevision: ${var.helmchart_rev}
        path: k3s-basecamp/k8s-apps/helm/data-docker
        helm:
          parameters:
          - name:  registry.secrets.s3.accessKey
            value: ${var.docker_registry_access_key}
          - name:  registry.secrets.s3.secretKey
            value: ${var.docker_registry_secret_key}
          - name:  registry.s3.region
            value: ${var.aws_region}
          - name:  registry.s3.regionEndpoint
            value: ${var.aws_s3_endpoint}
          - name:  registry.s3.bucket
            value: ${var.docker_registry_s3_bucket}
          - name:  oauth2-poxy.extraEnv[0].value
            value: "${var.github_orgs[0]}"
          - name:  oauth2-proxy.ingress.hosts[0]
            value: docker.${var.domain_name}
          - name:  oauth2-proxy.ingress.tls[0].hosts[0]
            value: docker.${var.domain_name}
          valueFiles:
          - values.yaml
          version: v2
      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.docker_namespace}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - Validate=true
    EOF
  EOT
}

################################################################
##
##  Kubernetes Secret
##

resource random_string docker_oauth2_cookie_secret {
  length = 32
  upper = false
  special = false
}

resource kubernetes_secret docker_oauth2 {
  metadata {
    name = "docker-registry-web-oauth2-secret"
    namespace = kubernetes_namespace.docker.metadata[0].name
  }

  data = {
    client-id = var.docker_github_client.id
    client-secret = var.docker_github_client.secret
    cookie-secret = random_string.docker_oauth2_cookie_secret.result
  }
}
