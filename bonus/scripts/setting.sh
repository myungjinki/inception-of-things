echo 'alias k=kubectl' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

# install kubectl
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s - server --disable=traefik

# install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install -y apt-transport-https
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

# setting gitlab
kubectl create ns gitlab
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --namespace gitlab \
	--install gitlab gitlab/gitlab \
	--set global.hosts.domain=192.168.56.110.nip.io \
	--set global.hosts.externalIP=192.168.56.110 \
	--set global.ingress.tls.enabled=false \
	--set global.hosts.https=false \
	--set global.ingress.configureCertmanager=false \
	--set global.edition=ce \
	--set global.shell.port=4242

until [ $(kubectl get deploy -n gitlab gitlab-webservice-default -ojsonpath='{.status.availableReplicas}') -ne 0 ] 2> /dev/null; do
	sleep 1
	echo 'waiting for gitlab ready...'
done

echo $'\e[92mAll done!\e[0m\nYou can start with root password:' $(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode)
