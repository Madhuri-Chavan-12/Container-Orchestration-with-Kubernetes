
# Kubernetes Cluster Setup using Terraform & Ansible on AWS EC2

This project automates the provisioning and configuration of a Kubernetes cluster on AWS EC2 using **Terraform** and **Ansible**.


## Project Overview

This setup follows an Infrastructure as Code (IaC) approach:

- **Terraform** → Creates EC2 instances (1 Master + 2 Workers)
- **Ansible** → Configures instances & installs Kubernetes
- **Kubeadm** → Initializes cluster and joins worker nodes


## Architecture


Terraform → EC2 Instances  
↓  
Ansible → Configure Nodes  
↓  
Kubeadm Init (Master)  
↓  
Workers Join Cluster  
↓  
Kubernetes Cluster Ready  



## Project Structure


k8s-setup/  
├── main.tf         # Terraform configuration  
├── inventory.ini   # Ansible inventory (Master & Workers)  
├── playbook.yaml   # Ansible playbook for K8s setup  
├── .gitignore  




## Prerequisites

- AWS Account
- Terraform installed
- Ansible installed
- SSH Key (.pem file)
- Open ports in Security Group:
  - 22 (SSH)
  - 6443 (K8s API)
  - 10250, 30000-32767 (Node ports)



## Step-by-Step Setup

### 1️⃣ Provision Infrastructure (Terraform)

```bash
terraform init
terraform validate
terraform plan
terraform apply
```
2️⃣ Configure SSH Access  
```
chmod 400 keightsrootkey.pem
```
Test connection:
```
ssh -i keightsrootkey.pemubuntu@<master-ip>
```
3️⃣ Install Ansible  
```
sudo apt update
sudo apt install ansible -y
```
4️⃣ Verify Connectivity  
```
ansible -i inventory.ini all -m ping
```
5️⃣ Run Ansible Playbook  
```
ansible-playbook -i inventory.ini playbook.yaml
```
What This Playbook Does  
**On All Nodes:**  
* Installs dependencies
* Configures kernel modules
* Sets sysctl networking parameters
* Disables swap
* Installs containerd
* Installs kubeadm, kubelet, kubectl

**On Master Node:**
* Initializes Kubernetes cluster
* Sets up kubeconfig
* Generates join command

**On Worker Nodes:** 
* Joins cluster using token
  
## Setup CNI (Networking) — REQUIRED  

```
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```
**Verify Cluster**
```
kubectl get nodes**
```
**Expected Output:**
```
master    Ready
worker1   Ready
worker2   Ready
```
**Test Deployment**  
```
kubectl create deployment nginx --image=nginx
kubectl get pods
```
 **.gitignore**  
```
*.pem
*.tfstate
*.tfstate.backup
.terraform/
```

**Key Learnings**  
* Infrastructure as Code using Terraform  
* Configuration management using Ansible  
* Kubernetes cluster setup using kubeadm  
* Networking and container runtime configuration  
