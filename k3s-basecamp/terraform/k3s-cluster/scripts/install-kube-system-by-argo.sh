#!/bin/sh -eux

argocd --config $CONFIG \
       --grpc-web \
       --insecure \
       app create kube-system \
       --dest-namespace kube-system \
       --dest-server https://kubernetes.default.svc \
       --helm-set-string RoleARN=http://${ROLE_ARN} \
       --helm-set-string EC2PrivateDNSName=${EC2_PRIVATE_DNS_NAME} \
       --path k3s-basecamp/helm/kube-system \
       --project default \
       --repo https://github.com/ghilbut/byfs-modules.git \
       --revision $REVISION \
       --sync-option Prune=true
