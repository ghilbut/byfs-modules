#!/bin/sh -eux

helm --kubeconfig $KUBECONFIG uninstall manager-argo --namespace manager-argo
kubectl --kubeconfig $KUBECONFIG delete namespace manager-argo
rm -rf $(dirname $ARGOCONFIG)

