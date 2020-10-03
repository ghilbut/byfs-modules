#!/bin/sh -eux

argocd --config $CONFIG \
       --grpc-web \
       --insecure \
       app create manager-argo \
       --dest-namespace manager-argo \
       --dest-server https://kubernetes.default.svc \
       --path k3s-basecamp/helm/manager-argo \
       --project default \
       --repo https://github.com/ghilbut/byfs-modules.git \
       --revision $REVISION \
       --helm-set-string cd.server.config.url=http://${HOST} \
       --helm-set-string cd.server.ingress.hosts[0]=${HOST} \
       --sync-option Prune=true

exit 0

argocd --config $CONFIG \
       --grpc-web \
       --insecure \
       app create manager-argo \
       --dest-namespace manager-argo \
       --dest-server https://kubernetes.default.svc \
       --path k3s-basecamp/helm/manager-argo \
       --project default \
       --repo https://github.com/ghilbut/byfs-modules.git \
       --revision $REVISION \
       --helm-set-string cd.server.config.url=http://${HOST} \
       --helm-set-string cd.server.ingress.hosts[0]=${HOST} \
       --helm-set-string cd.server.ingress.tls[0].hosts[0]=${HOST} \
       --sync-option Prune=true
