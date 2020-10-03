#!/bin/sh -eux

helm --kubeconfig $KUBECONFIG uninstall k8s-network --namespace k8s-network
kubectl --kubeconfig $KUBECONFIG delete namespace k8s-network
