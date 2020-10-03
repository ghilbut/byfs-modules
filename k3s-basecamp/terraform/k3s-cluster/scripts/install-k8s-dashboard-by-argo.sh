#!/bin/sh -eux

argocd --config $CONFIG \
       --grpc-web \
       --insecure \
       app create k8s-dashboard \
       --auto-prune \
       --dest-namespace k8s-dashboard \
       --dest-server https://kubernetes.default.svc \
       --path k3s-basecamp/helm/k8s-dashboard \
       --project default \
       --repo https://github.com/ghilbut/byfs-modules.git \
       --revision $REVISION \
       --self-heal \
       --sync-option Prune=true \
       --sync-policy automated
