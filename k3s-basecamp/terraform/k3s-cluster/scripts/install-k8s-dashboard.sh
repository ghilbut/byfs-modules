#!/bin/sh -eux

helm --kubeconfig $KUBECONFIG \
     --namespace k8s-dashboard \
     install k8s-dashboard $HELM_CHART_PATH \
     --create-namespace \
     --dependency-update \
     --set kubernetes-dashboard.ingress.hosts[0]=${HOST} \
     --wait

exit 0

helm --kubeconfig $KUBECONFIG \
     --namespace k8s-dashboard \
     install k8s-dashboard $HELM_CHART_PATH \
     --create-namespace \
     --dependency-update \
     --set kubernetes-dashboard.ingress.hosts[0]=${HOST} \
     --set kubernetes-dashboard.ingress.tls[0].hosts[0]=${HOST} \
     --wait
