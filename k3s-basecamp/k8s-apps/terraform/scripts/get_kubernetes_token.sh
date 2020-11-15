#!/bin/sh
export KUBECONFIG_PATH=$1
export NAMESPACE=kube-dashboard
export TOKEN=$(kubectl --kubeconfig $KUBECONFIG_PATH \
                       --namespace $NAMESPACE describe secret \
                       $(kubectl --kubeconfig $KUBECONFIG_PATH \
                                 --namespace $NAMESPACE get secret \
                         | grep k3s-basecamp \
                         | awk '{print $1}') \
               | grep token: \
               | awk '{print $2}')
echo "{ \"token\": \"$TOKEN\" }"
