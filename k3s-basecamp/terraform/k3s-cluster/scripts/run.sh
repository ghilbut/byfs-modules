#!/bin/sh -eux

export PRIVATE_IP=$1
export PUBLIC_IP=$2
export PUBLIC_KEY=$3
export KUBECONFIG=$4
export ARGOCONFIG=$5
export DOMAIN_NAME=$6
export ARGOCD_HOST=argo.$DOMAIN_NAME
export ARGOCD_PASSWORD=$7

## get kubeconfig
rm -rf $(dirname $KUBECONFIG)
mkdir -p $(dirname $KUBECONFIG)
scp -i $PUBLIC_KEY \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -q \
    ubuntu@${PUBLIC_IP}:/etc/rancher/k3s/k3s.yaml \
    $(dirname $KUBECONFIG)
sed -i -e "s/127\.0\.0\.1/k3s.${DOMAIN_NAME}/g" $KUBECONFIG

kubectl --kubeconfig $KUBECONFIG create namespace k3s-network

## helm install metallb
# helm repo add bitnami https://charts.bitnami.com/bitnami
helm install metallb bitnami/metallb \
     --kubeconfig $KUBECONFIG \
     --namespace k3s-network \
     --set configInline.address-pools[0].name=default \
     --set configInline.address-pools[0].protocol=layer2 \
     --set configInline.address-pools[0].addresses[0]=192.168.0.240-192.168.0.250 \
     --wait
#helm install metallb bitnami/metallb \
#     --kubeconfig ${local.kubeconfig} \
#     --namespace kube-system \
#     --name-template=kube-system \
#     --set configInline.address-pools[0].name=default \
#     --set configInline.address-pools[0].protocol=layer2 \
#     --set configInline.address-pools[0].addresses[0]=192.168.0.240-192.168.0.250

## helm install ingress-nginx
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
     --kubeconfig $KUBECONFIG \
     --namespace k3s-network \
     --set controller.service.externalIPs[0]=${PRIVATE_IP} \
     --wait
#helm install ingress-nginx ingress-nginx/ingress-nginx \
#     --kubeconfig ${local.kubeconfig} \
#     --namespace kube-system \
#     --name-template=kube-system \
#     --set controller.service.externalIPs[0]=${aws_instance.centre.private_ip}

## helm install cert-manager
# helm repo add jetstack https://charts.jetstack.io
helm install cert-manager cert-manager \
     --kubeconfig $KUBECONFIG \
     --namespace k3s-network \
     --repo https://charts.jetstack.io \
     --set installCRDs=true \
     --wait


kubectl --kubeconfig $KUBECONFIG create namespace manager-argo

## helm install argo-cd
#kubectl --kubeconfig $KUBECONFIG create namespace manager-argo
# helm repo add argo https://argoproj.github.io/argo-helm
helm install argo/argo-cd \
     --kubeconfig $KUBECONFIG \
     --namespace manager-argo \
     --name-template=manager-argo \
     --set nameOverride=argocd \
     --set server.extraArgs[0]=--insecure \
     --set server.ingress.enabled=true \
     --set server.ingress.hosts[0]=${ARGOCD_HOST} \
     --wait
#     --set server.extraArgs[0]=--insecure \
#     --set server.ingress.enabled=true \
#     --set server.ingress.hosts[0]=${ARGOCD_HOST} \
#     --wait

#while [[ "$(curl -s -o /dev/null -L -w %{http_code} http://${ARGOCD_HOST})" != "200" ]]
#do
#  echo "Waiting $ARGOCD_HOST online"
#  sleep 5
#done
#curl -i http://${ARGOCD_HOST}

# login and achange argo-cd password
rm -rf $(dirname $ARGOCONFIG)
mkdir -p $(dirname $ARGOCONFIG)
export ARGOPW=$(kubectl get pods \
                        --kubeconfig $KUBECONFIG \
                        --namespace manager-argo \
                        -l app.kubernetes.io/name=argocd-server \
                        -o name \
                        | cut -d'/' -f 2)
argocd --config $ARGOCONFIG \
       --grpc-web \
       --insecure \
       login $ARGOCD_HOST \
       --name k3s-centre \
       --username admin \
       --password $ARGOPW
argocd --config $ARGOCONFIG \
       --grpc-web \
       --insecure \
       account update-password \
       --current-password $ARGOPW \
       --new-password "$ARGOCD_PASSWORD"



helm --kubeconfig ../.kube/k3s.yaml \
     --namespace manager-argo \
     install argo-cd \
     --create-namespace \
     --name-template=manager-argo \
     --repo https://argoproj.github.io/argo-helm \
     --set nameOverride=argocd \
     --set server.extraArgs[0]=--insecure \
     --set server.ingress.enabled=true \
     --set server.ingress.hosts[0]=argo.ghilbut.net \
     --wait


helm --kubeconfig ../.kube/k3s.yaml uninstall manager-argo --namespace manager-argo
kubectl --kubeconfig ../.kube/k3s.yaml delete namespace manager-argo
rm -rf ../.argo

