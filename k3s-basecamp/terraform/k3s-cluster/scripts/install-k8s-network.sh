#!/bin/sh -eux

export KUBECONFIG=$1
export HELM_INSTALL_CHART_PATH=$2
export HELM_SETTINGS_CHART_PATH=$3
export EXTERNAL_IP=$4

helm dependency update $HELM_INSTALL_CHART_PATH
helm --kubeconfig $KUBECONFIG \
     --namespace k8s-network \
     install k8s-network $HELM_INSTALL_CHART_PATH \
     --create-namespace \
     --dependency-update \
     --set ingress-nginx.controller.service.externalIPs[0]=${EXTERNAL_IP} \
     --wait
helm --kubeconfig $KUBECONFIG \
     --namespace k8s-network \
     install k8s-network-issuers $HELM_SETTINGS_CHART_PATH \
     --wait
