#!/bin/bash

kubectl delete ns gitlab
kubectl delete ns dev
kubectl delete ns argocd

k3d cluster delete argocd
