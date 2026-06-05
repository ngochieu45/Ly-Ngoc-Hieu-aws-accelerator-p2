#!/bin/bash

set -e

# =========================
# Update system
# =========================
dnf update -y

# =========================
# Install Docker
# =========================
dnf install -y docker

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

# =========================
# Install kubectl
# =========================
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# =========================
# Install Minikube
# =========================
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

install minikube-linux-amd64 /usr/local/bin/minikube

# =========================
# Install socat
# =========================
dnf install -y socat

# =========================
# Start Minikube
# =========================
sudo -u ec2-user minikube start \
  --driver=docker \
  --memory=2048 \
  --cpus=2

# Wait cluster ready
sleep 30

# =========================
# Deployment
# =========================
cat <<EOF >/home/ec2-user/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
      - name: hello-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args:
        - echo '<h1>Hello XBrain x AWS</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
EOF

# =========================
# Service
# =========================
cat <<EOF >/home/ec2-user/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-app-service
spec:
  type: NodePort
  selector:
    app: hello-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF

chown ec2-user:ec2-user \
  /home/ec2-user/deployment.yaml \
  /home/ec2-user/service.yaml

# =========================
# Deploy app
# =========================
sudo -u ec2-user kubectl apply -f /home/ec2-user/deployment.yaml

sudo -u ec2-user kubectl apply -f /home/ec2-user/service.yaml

# Wait service ready
sleep 20

# =========================
# Expose NodePort to EC2 host
# =========================
MINIKUBE_IP=$(sudo -u ec2-user minikube ip)

nohup socat \
TCP-LISTEN:30080,reuseaddr,fork \
TCP:${MINIKUBE_IP}:30080 \
>/var/log/socat.log 2>&1 &

# =========================
# Debug info
# =========================
echo "Minikube IP: ${MINIKUBE_IP}" >> /var/log/minikube-bootstrap.log

sudo -u ec2-user kubectl get pods -A \
>> /var/log/minikube-bootstrap.log 2>&1

sudo -u ec2-user kubectl get svc -A \
>> /var/log/minikube-bootstrap.log 2>&1