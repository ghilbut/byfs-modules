#!/bin/sh -eux

helm --kubeconfig $KUBECONFIG --namespace k8s-dashboard uninstall k8s-dashboard
kubectl --kubeconfig $KUBECONFIG delete namespace k8s-dashboard
