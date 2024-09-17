#!/bin/bash

# Step 0: Get user input for necessary details
read -p "Enter IAM Policy Name [default: Amazon_EBS_CSI_Driver]: " IAM_POLICY_NAME
IAM_POLICY_NAME=${IAM_POLICY_NAME:-Amazon_EBS_CSI_Driver}

read -p "Enter IAM Policy Description [default: 'Policy for EC2 Instances to access Elastic Block Store']: " IAM_POLICY_DESCRIPTION
IAM_POLICY_DESCRIPTION=${IAM_POLICY_DESCRIPTION:-"Policy for EC2 Instances to access Elastic Block Store"}

read -p "Enter EKS Cluster Name [default: eksdemo1]: " EKS_CLUSTER_NAME
EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME:-eksdemo1}

read -p "Enter EKS Nodegroup Role Name Prefix (e.g., eksctl-eksdemo1-nodegroup) [default: eksctl-eksdemo1-nodegroup]: " EKS_NODEGROUP_ROLE_NAME
EKS_NODEGROUP_ROLE_NAME=${EKS_NODEGROUP_ROLE_NAME:-eksctl-eksdemo1-nodegroup}

# Get kubectl version
KUBECTL_VERSION=$(kubectl version --client --short | awk '{print $3}')

# Step 1: Create IAM Policy for EBS
echo "Creating IAM policy for EBS..."

POLICY_JSON=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)

aws iam create-policy --policy-name $IAM_POLICY_NAME --policy-document "$POLICY_JSON" --description "$IAM_POLICY_DESCRIPTION"

# Step 2: Associate IAM Policy with Worker Node Role
echo "Associating IAM policy to worker node IAM role..."

# Get Worker Node IAM Role ARN from aws-auth configmap
WORKER_ROLE_ARN=$(kubectl -n kube-system describe configmap aws-auth | grep -o 'arn:aws:iam::[0-9]*:role/[a-zA-Z0-9\-]*')

# Extract role name from ARN
ROLE_NAME=$(echo $WORKER_ROLE_ARN | cut -d'/' -f2)

# Attach policy to the worker node role
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/$IAM_POLICY_NAME

echo "Policy attached to IAM role: $ROLE_NAME"

# Step 3: Deploy Amazon EBS CSI Driver
echo "Deploying Amazon EBS CSI Driver..."

# Verify kubectl version is 1.14 or later
if [[ $KUBECTL_VERSION > "v1.14" ]]; then
  echo "kubectl version is $KUBECTL_VERSION. Proceeding with EBS CSI Driver deployment..."
else
  echo "kubectl version is less than 1.14. Please upgrade to proceed."
  exit 1
fi

# Deploy EBS CSI Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

# Verify the deployment
echo "Verifying EBS CSI Driver deployment..."
kubectl get pods -n kube-system | grep ebs-csi

echo "Amazon EBS CSI Driver installation completed successfully."
