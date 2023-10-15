# REFERENCES: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# Container runtime: https://kubernetes.io/docs/setup/production-environment/container-runtimes/


#?--------------------------------------
#? Update & install required package
#?--------------------------------------
#sudo mkdir -p /etc/apt/keyrings
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
#?-------------------------------------------
#? Download Google Cloud public signing key
#?-------------------------------------------
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

#?---------------------------
#? Add K8s apt repository
#?---------------------------
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#?----------------------------------
#? Install kubelet,kubeadm,kubectl
#?----------------------------------
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#?----------------------------------
#? Containerd cgroup driver
#?----------------------------------
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
#sudo sed -i 's/systemd_cgroup = false/systemd_cgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Sleep for 3s to ensure containerd startup properly
sleep 3

#?-----------------------------
#? Init K8s Cluster
#?-----------------------------
sudo kubeadm init  --cri-socket /run/containerd/containerd.sock --pod-network-cidr=10.10.0.0/16 --upload-certs -v=5 | tee ~/kadm-init.out

#?-----------------------------
#? Setup .kube/config file
#?-----------------------------
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#?-----------------------------
#? Install CNI & Untaint node
#?-----------------------------
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml
#kubectl taint node $(hostname) node-role.kubernetes.io/master:NoSchedule-
kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-

#?--------------------------------
#? Setup kubectl autocompletion
#?--------------------------------
echo "source <(kubectl completion bash)" >> ~/.bashrc
source <(kubectl completion bash)
