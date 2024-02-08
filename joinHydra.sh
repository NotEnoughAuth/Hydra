#!/bin/bash
# Join the hydra network that was created by the createHydra.sh script
# install k3s, and longhorn dependencies

# ask the user for the virtual ip that is used to communicate with the k3s cluster
read -p "Enter the Virtual IP address of the cluster: " VIP

# longhorn dependencies
if [ -x "$(command -v apt)" ]; then
    apt install -y open-iscsi nfs-common
elif [ -x "$(command -v dnf)" ]; then
    dnf install -y iscsi-initiator-utils nfs-utils
elif [ -x "$(command -v yum)" ]; then
    yum install -y iscsi-initiator-utils nfs-utils
fi

#  enable the iscsid service
systemctl enable --now open-iscsi

# Ask the user for the token
read -p "Enter the token of the cluster: " TOKEN

# Join the k3s cluster
curl -sfL https://get.k3s.io | K3S_URL=https://$VIP:6443 K3S_TOKEN=$TOKEN sh -

# Ensure that docker is installed
if [ -x "$(command -v apt)" ]; then
    apt install -y docker.io
elif [ -x "$(command -v dnf)" ]; then
    dnf install -y docker
elif [ -x "$(command -v yum)" ]; then
    yum install -y docker
fi

# Start and enable docker
systemctl enable --now docker

# Install jq
if [ -x "$(command -v apt)" ]; then
    apt install -y jq
elif [ -x "$(command -v dnf)" ]; then
    dnf install -y jq
elif [ -x "$(command -v yum)" ]; then
    yum install -y jq
fi

# Install kube-vip
read -p "Enter the network interface to use: " INTERFACE

clear
# ask to verify the network interface
echo "The network interface to use is $INTERFACE"
read -p "Is this correct? (y/n): " correct
if [ "$correct" == "n" ]; then
    read -p "Enter the network interface to use: " INTERFACE
fi

KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")

alias kube-vip="docker run --network host --rm ghcr.io/kube-vip/kube-vip:$KVVERSION"

kube-vip manifest pod --interface $INTERFACE --address $VIP --controlplane --services --arp --leaderElection | tee /etc/kubernetes/manifests/kube-vip.yaml
