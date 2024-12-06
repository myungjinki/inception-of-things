#!/bin/bash

if ! type kubectl 2> /dev/null; then
    brew install kubectl
fi
if ! type k3d 2> /dev/null; then
	brew install k3d
fi

k3d cluster create argocd -p "9999:9999@loadbalancer" -p "8888:8888@loadbalancer" -p "80:80@loadbalancer"
kubectl create ns argocd
kubectl create ns dev
kubectl create ns gitlab

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch deploy argocd-server -n argocd --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'

kubectl get cm argocd-cm -n argocd -o yaml > tmp.yml
echo $'data:\n  timeout.reconciliation: 10s' >> tmp.yml
kubectl apply -f tmp.yml && rm tmp.yml
kubectl rollout restart deploy argocd-repo-server -n argocd
until kubectl get svc -n kube-system | grep -q traefik; do
	sleep 1
done
kubectl patch svc traefik -n kube-system -p '{"spec":{"ports":[{"name":"wil","port":8888,"targetPort":"wil"},{"name":"glab","port":9999,"targetPort":"glab"}]}}'

kubectl patch deploy traefik -n kube-system --type='json' -p='[
    {"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"containerPort": 8888, "name": "wil", "protocol": "TCP"}},
    {"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"containerPort": 9999, "name": "glab", "protocol": "TCP"}},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--entrypoints.wil.address=:8888/tcp"},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--entrypoints.glab.address=:9999/tcp"}
]'

until kubectl get crd | grep -q 'ingressroutes.traefik.containo.us'; do
	echo 'waiting for CRD...'
	sleep 1
done
kubectl apply -f ../confs/mand

until [ $(kubectl get deploy -n argocd argocd-server -ojsonpath='{.status.availableReplicas}') -ne 0 ] 2> /dev/null; do
	sleep 1
	echo 'waiting for argocd ready...'
done
echo $'\e[92mSetting done!\e[0m\nYou can start with admin password:' $(kubectl get secret argocd-initial-admin-secret -n argocd -o json | grep password | awk '{gsub(/"/, "", $2); print $2}'| base64 --decode)
