#!/bin/bash

# Hostname configuration
sudo hostnamectl set-hostname ${hostname}

# K3s server installation
curl -sfL https://get.k3s.io | sh -s - server --token 12345 --write-kubeconfig-mode 644

# Argo CLI installation
curl -sLO https://github.com/argoproj/argo-workflows/releases/download/v3.4.2/argo-linux-amd64.gz
gunzip argo-linux-amd64.gz
chmod +x argo-linux-amd64
mv ./argo-linux-amd64 /usr/local/bin/argo

# Install Helm CLI
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Argo Workflows Helm chart
helm --kubeconfig /etc/rancher/k3s/k3s.yaml \
     install argo-workflows https://github.com/argoproj/argo-helm/releases/download/argo-workflows-0.20.4/argo-workflows-0.20.4.tgz \
     --namespace argo --create-namespace \
     --set server.baseHref="/argo-workflows/" \
     --set server.extraArgs[0]="--auth-mode=server" \
     --set server.extraArgs[1]="--access-control-allow-origin=*" \
     --set server.ingress.enabled="true" \
     --set server.ingress.paths[0]="/argo-workflows/" \
     --set server.ingress.annotations."traefik\.ingress\.kubernetes\.io/router\.middlewares"="argo-urlrewrite@kubernetescrd" \
     --atomic

# Install Argo CD Helm chart
helm --kubeconfig /etc/rancher/k3s/k3s.yaml \
     install argo-cd https://github.com/argoproj/argo-helm/releases/download/argo-cd-5.8.2/argo-cd-5.8.2.tgz \
     --namespace argo --create-namespace \
     --set configs.params."server\.insecure"="true" \
     --set configs.params."server\.basehref"="/argo-cd/" \
     --set server.ingress.enabled="true" \
     --set server.ingress.paths[0]="/argo-cd/" \
     --set server.ingress.annotations."traefik\.ingress\.kubernetes\.io/router\.middlewares"="argo-urlrewrite@kubernetescrd" \
     --atomic

# Configure a Traefik middleware to support Ingress Prefixed Path URL rewriting
cat <<EOF | kubectl apply -f -
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: urlrewrite
  namespace: argo
spec:
  replacePathRegex:
    regex: ^/argo-(workflows|cd)/(.*)$
    replacement: /\$2
EOF