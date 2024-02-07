# Downloads and configures a kubernetes cluster using k3s kubevip and metallb and longhorn

# Config Settings
export SERVICE_IP="192.168.134.201"
export INTERNAL_IP="192.168.134.200"

# Ask the user for the service ip and internal ip
# read -p "Enter the service ip address: " SERVICE_IP
# read -p "Enter the internal ip address: " INTERNAL_IP


# Ask the user for Virtual IP
read -p "Enter the Virtual IP address: " VIP

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Configuration settings for kube-vip
# VIP="192.168.1.200"
INTERFACE="eth0"
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")

alias kube-vip="docker run --network host --rm ghcr.io/kube-vip/kube-vip:$KVVERSION"

kube-vip manifest pod --interface $INTERFACE --address $VIP --controlplane --services --arp --leaderElection | tee /etc/kubernetes/manifests/kube-vip.yaml

# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# Configure MetalLB
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.9.1-192.168.9.5
EOF

# Install longhorn
# Ensure that longhorn dependencies are installed on any package manager
if [ -x "$(command -v apt)" ]; then
    apt install -y open-iscsi nfs-common
elif [ -x "$(command -v dnf)" ]; then
    dnf install -y iscsi-initiator-utils nfs-utils
elif [ -x "$(command -v yum)" ]; then
    yum install -y iscsi-initiator-utils nfs-utils
fi

#  enable the iscsid service
systemctl enable --now open-iscsi

# Install Longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml


# Deploy a container registry for the cluster
# Create registry namespace
kubectl create namespace container-registry

# Create a longhorn pvc for the registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-pvc
  namespace: container-registry
spec:
    accessModes:
    - ReadWriteOnce
    resources:
        requests:
        storage: 10Gi
EOF

# Deploy the registry
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: container-registry
spec:
    replicas: 3
    selector:
        matchLabels:
        app: registry
    template:
        metadata:
        labels:
            app: registry
        spec:
        containers:
        - name: registry
            image: registry:2
            ports:
            - containerPort: 5000
            volumeMounts:
            - mountPath: /var/lib/registry
            name: registry-storage
        volumes:
        - name: registry-storage
            persistentVolumeClaim:
            claimName: registry-pvc
EOF

# Expose the registry to the internal metallb ip address
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: container-registry
spec:
    selector:
        app: registry
    ports:
    - protocol: TCP
        port: 5000
        targetPort: 5000
    type: LoadBalancer
    loadBalancerIP: $INTERNAL_IP
EOF
