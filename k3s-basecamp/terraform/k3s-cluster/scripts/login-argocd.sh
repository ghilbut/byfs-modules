#!/bin/sh -eux

mkdir $(dirname $ARGOCONFIG)
argocd --config $ARGOCONFIG \
       --grpc-web \
       --insecure \
       login $ARGOCD_HOST \
       --name k3s-basecamp \
       --username admin \
       --password "$ARGOCD_PASSWORD"
