#!/bin/sh -eux

argocd --config $ARGOCONFIG \
       --grpc-web \
       --insecure \
       logout k3s-basecamp
rm -rf $(dirname $ARGOCONFIG)
