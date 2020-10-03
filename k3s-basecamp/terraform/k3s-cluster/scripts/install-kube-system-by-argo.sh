#!/bin/sh -eux

argocd --config $CONFIG \
       --grpc-web \
       --insecure \
       app create kube-system \
       --dest-namespace kube-system \
       --dest-server https://kubernetes.default.svc \
       --path k3s-basecamp/helm/kube-system \
       --project default \
       --repo https://github.com/ghilbut/byfs-modules.git \
       --revision $REVISION \
       --sync-option Prune=true
