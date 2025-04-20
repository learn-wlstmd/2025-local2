#!/bin/bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

sudo yum install docker -y
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker root
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

docker --version

yum install python3 python3-pip -y

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
eksctl version

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version

cat << EOF > order-v1.py
import os
import boto3
from datetime import datetime

from time import sleep

QUEUE_URL = os.environ["QUEUE_URL"]
REGION_NAME = os.environ["REGION_NAME"]

client = boto3.client("sqs", region_name=REGION_NAME)

while True:
    print(datetime.now())
    try:
        response = client.receive_message(QueueUrl=QUEUE_URL, MaxNumberOfMessages=1)
    except Exception as e:
        print(e)
        print(flush=True)
        sleep(30)
        continue

    messages = response.get("Messages", [])
    if not messages:
        print("There's nothing in a queue...")

    for message in messages:
        client.delete_message(
            QueueUrl=QUEUE_URL, ReceiptHandle=message["ReceiptHandle"]
        )
        print(message["Body"])

    print(flush=True)
    sleep(30)
EOF

cat << EOF > Dockerfile
FROM python:3.13-slim

WORKDIR /app

COPY order-v1.py .

RUN pip install --no-cache-dir boto3

CMD ["python", "order-v1.py"]
EOF

aws sqs create-queue --queue-name order-queue

aws ecr create-repository --repository-name order-app --region ap-northeast-2

docker build -t order-app:v1 .
docker tag order-app:v1 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/order-app:v1
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com
docker push 362708816803.dkr.ecr.ap-northeast-2.amazonaws.com/order-app:v1

cat << EOF > cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: order-cluster
  version: "1.31"
  region: ap-northeast-2

cloudWatch:
  clusterLogging:
    enableTypes: ["*"]

iam:
  withOIDC: true
  serviceAccounts:
    - metadata:
        name: aws-load-balancer-controller
        namespace: kube-system
      wellKnownPolicies:
        awsLoadBalancerController: true
    - metadata:
        name: cert-manager
        namespace: cert-manager
      wellKnownPolicies:
        certManager: true

vpc:
  subnets:
    public:
      ap-northeast-2a: { id: public_a }
      ap-northeast-2b: { id: public_b }
    private:
      ap-northeast-2a: { id: private_a }
      ap-northeast-2b: { id: private_b }

managedNodeGroups:
  - name: order-app-nodegroup
    instanceName: order-app-node
    instanceType: c5.large
    desiredCapacity: 2
    minSize: 2
    maxSize: 4
    privateNetworking: true
EOF

public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=keda-public-subnet-a" --query "Subnets[].SubnetId[]" --region ap-northeast-2 --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=keda-public-subnet-b" --query "Subnets[].SubnetId[]" --region ap-northeast-2 --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=keda-private-subnet-a" --query "Subnets[].SubnetId[]" --region ap-northeast-2 --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=keda-private-subnet-b" --query "Subnets[].SubnetId[]" --region ap-northeast-2 --output text)

sed -i "s|public_a|$public_a|g" cluster.yaml
sed -i "s|public_b|$public_b|g" cluster.yaml
sed -i "s|private_a|$private_a|g" cluster.yaml
sed -i "s|private_b|$private_b|g" cluster.yaml

eksctl create cluster -f cluster.yaml