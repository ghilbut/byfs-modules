#!/bin/sh -eux

export PUBLIC_IP=$1
export PUBLIC_KEY=$2
export KUBECONFIG=$3
export K3S_HOST=$4

## get kubeconfig
rm -rf $(dirname $KUBECONFIG)
mkdir -p $(dirname $KUBECONFIG)
scp -i $PUBLIC_KEY \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -q \
    ubuntu@${PUBLIC_IP}:/etc/rancher/k3s/k3s.yaml \
    $(dirname $KUBECONFIG)
sed -i -e "s/127\.0\.0\.1/${K3S_HOST}/g" $KUBECONFIG
