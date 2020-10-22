#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y \
    vim \
    httpie \
    jq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    conntrack \
    containernetworking-plugins \
    software-properties-common


# docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker ubuntu

# kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin

# helm
snap install helm --classic

# fix CNI
mkdir /opt/cni/
ln -s /usr/lib/cni /opt/cni/bin

# minikube 

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb

PUBIP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PUBDNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
FULLHOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/hostname)

sudo minikube config set driver none
sudo minikube start \
    --apiserver-name=$PUBDNS \
    --apiserver-port=58443 \
    --addons=metallb \
    --extra-config=apiserver.cloud-provider=aws \
    --extra-config=controller-manager.cloud-provider=aws \
    --extra-config=kubelet.cloud-provider=aws \
    --extra-config=kubeadm.node-name=$FULLHOSTNAME \
    --extra-config=kubelet.hostname-override=$FULLHOSTNAME
    

# ingress with hostnetwork
sudo helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
sudo helm repo add stable https://kubernetes-charts.storage.googleapis.com/
sudo helm repo update
sudo helm install ingress ingress-nginx/ingress-nginx --set controller.hostPort.enabled=true

# delete standard storageclass
# TODO: fix storage - 777 perms are invalid for some apps
sudo kubectl annotate sc standard storageclass.kubernetes.io/is-default-class-

cat << EOF | sudo kubectl apply -f-
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4 
EOF

# aws labels

sudo kubectl label node --all failure-domain.beta.kubernetes.io/region=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
sudo kubectl label node --all failure-domain.beta.kubernetes.io/zone=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .availabilityZone)
sudo kubectl taint nodes --all node-role.kubernetes.io/master-
sudo kubectl label nodes --all node-role.kubernetes.io/master-

# metallb
# sudo minikube addons enable metallb

TMPCM=$(mktemp)
cat <<EOF > $TMPCM
address-pools:
- name: default
  protocol: layer2
  addresses:
  - ${PUBIP}-${PUBIP}
EOF

sudo kubectl create configmap config --from-file=config=$TMPCM --dry-run=client -o yaml | \
    sudo kubectl apply -f- -n metallb-system
sudo kubectl delete pod -lapp=metallb -n metallb-system