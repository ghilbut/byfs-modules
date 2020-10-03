#!/bin/sh -eux

export ENCPW=$(htpasswd -nbBC 10 "" "$ARGO_PASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/')
export MTIME=$(date -u +%FT%TZ)

helm --kubeconfig $KUBECONFIG \
     --namespace manager-argo \
     install manager-argo $HELM_CHART_PATH \
     --create-namespace \
     --dependency-update \
     --set cd.server.config.url=http://${HOST} \
     --set cd.server.ingress.hosts[0]=${HOST} \
     --set cd.configs.secret.argocdServerAdminPassword=${ENCPW} \
     --set cd.configs.secret.argocdServerAdminPasswordMtime=${MTIME} \
     --set cd.configs.secret.extra."dex\.github\.clientID"=${GITHUB_CLIENT_ID} \
     --set cd.configs.secret.extra."dex\.github\.clientSecret"=${GITHUB_CLIENT_SECRET} \
     --wait

exit 0

helm --kubeconfig $KUBECONFIG \
     --namespace manager-argo \
     install manager-argo $HELM_CHART_PATH \
     --create-namespace \
     --dependency-update \
     --set cd.server.config.url=https://${HOST} \
     --set cd.server.ingress.hosts[0]=${HOST} \
     --set cd.server.ingress.tls[0].hosts[0]=${HOST} \
     --set cd.configs.secret.argocdServerAdminPassword=${ENCPW} \
     --set cd.configs.secret.argocdServerAdminPasswordMtime=${MTIME} \
     --set cd.configs.secret.extra."dex\.github\.clientID"=${GITHUB_CLIENT_ID} \
     --set cd.configs.secret.extra."dex\.github\.clientSecret"=${GITHUB_CLIENT_SECRET} \
     --wait
