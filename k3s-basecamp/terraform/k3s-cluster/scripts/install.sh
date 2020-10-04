# Dashboard admin-user token
kubectl -n k8s-dashboard describe secret $(kubectl -n k8s-dashboard get secret | grep admin-user | awk '{print $1}') | grep token: | awk '{print $2}'
