sudo apt update -y
sudo apt upgrade -y

# install k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export K3S_KUBECONFIG_MODE="644"
export INSTALL_K3S_EXEC=" --no-deploy servicelb --no-deploy traefik"
curl -sfL https://get.k3s.io | sh -
sudo chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml

# install helm v3
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update -y
sudo apt-get install -y helm

# apply helm stable repository
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update

# install MetalLB
# https://github.com/bitnami/charts/tree/master/bitnami/metallb
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install metallb bitnami/metallb --namespace kube-system \
  --set configInline.address-pools[0].name=default \
  --set configInline.address-pools[0].protocol=layer2 \
  --set configInline.address-pools[0].addresses[0]=192.168.0.240-192.168.0.250

# nginx-ingress
# https://github.com/kubernetes/ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace kube-system \
  --set controller.service.externalIPs[0]=172.31.9.211

# ArgoCD by helm
helm repo add argo https://argoproj.github.io/argo-helm
helm install argo/argo-cd \
  --namespace manager-argo \
  --name-template=manager-argo \
  --set nameOverride=argocd \
  --set server.extraArgs[0]=--insecure \
  --set server.ingress.enabled=true \
  --set server.ingress.hosts[0]=argo.m.ghilbut.net
## # get initial admin password
## $ kubectl get pods -n manager-argo -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
## ********
## login
## $ brew install argocd
## $ argocd --grpc-web --insecure login argo.m.ghilbut.net --name k3s-centre --username admin
## Password:
## $ argocd --grpc-web --insecure account update-password

# Dashboard admin-user token
kubectl -n k8s-dashboard describe secret $(kubectl -n k8s-dashboard get secret | grep admin-user | awk '{print $1}') | grep token: | awk '{print $2}'
