#!/bin/sh -eux

export K3S_KUBECONFIG_MODE=400
export INSTALL_K3S_EXEC='
   --disable-cloud-controller
   --kube-apiserver-arg cloud-provider=external
   --kube-apiserver-arg allow-privileged=true
   --kube-apiserver-arg feature-gates=CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true,VolumeSnapshotDataSource=true
   --kube-controller-arg cloud-provider=external
   --kubelet-arg feature-gates=CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true
   --no-deploy local-storage
   --no-deploy servicelb
   --no-deploy traefik
   --token ${TOKEN}'
curl -sfL https://get.k3s.io | sh -
sudo chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml
