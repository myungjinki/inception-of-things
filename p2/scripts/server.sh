#!/bin/bash

echo 'alias k=kubectl' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s - server
until kubectl get crd | grep -q 'ingressroutes.traefik.containo.us'; do
	echo 'waiting for CRD...'
	sleep 1
done
kubectl apply -f /etc/vagrant/confs

until [ ! -z "$(kubectl get pods -o jsonpath='{.items[*].metadata.name}')" ]; do
	sleep 1
done
for pod in $(kubectl get pods -o jsonpath='{.items[*].metadata.name}'); do
    until kubectl get pods $pod | grep -q 'Running'; do
        sleep 1
    done
	app_name=$(kubectl get pods $pod -o jsonpath='{.metadata.labels.app}')
    HTML=$(cat <<EOF
<!DOCTYPE html>
<html> 
<head> 
    <title>Hello Kubernetes!</title>
</head>
<body>

    <div class="main">
        <div class="content">
            <div id="message"> 
    Hello from ${app_name}.
</div>
<div id="info">
    <table> 
        <tr>
            <th>pod:</th> 
            <td>${pod}</td>
        </tr>
        <tr>
            <th>node:</th> 
            <td>$(uname -s) ($(uname -r))</td> 
        </tr> 
    </table>

</div> 
    </div> 
</div>
</body>
</html>
EOF
)
    echo $"${HTML}" > /home/vagrant/index.html
	kubectl cp /home/vagrant/index.html $pod:/usr/share/nginx/html/index.html > /dev/null
done
