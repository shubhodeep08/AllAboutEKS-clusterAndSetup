#!/bin/bash

# Function to prompt user input
prompt() {
  local varname=$1
  local prompt_text=$2
  local default_value=$3

  read -p "$prompt_text [Default: $default_value]: " input
  export $varname="${input:-$default_value}"
}

# Step 1: Collect necessary information from the user
echo "Please provide the following details for setting up the AWS ALB Controller on your EKS cluster."

# Get Cluster Name
prompt "CLUSTER_NAME" "Enter your EKS Cluster Name" "my-eks-cluster"

# Get AWS Region
prompt "REGION" "Enter the AWS Region" "us-west-2"

# Get VPC ID
prompt "VPC_ID" "Enter your VPC ID" "vpc-xxxxxxx"

# Get IAM Policy Name
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"

# Get AWS Account ID automatically
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Step 2: Associate IAM OIDC provider
echo "Associating IAM OIDC provider with the EKS cluster..."
eksctl utils associate-iam-oidc-provider \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --approve

# Step 3: Create IAM Policy for the ALB Controller
echo "Creating IAM policy for the ALB Controller..."
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://iam-policy.json

# Step 4: Create IAM Service Account for the ALB Controller
echo "Creating IAM service account for ALB Controller..."
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME \
  --approve

# Step 5: Install the AWS Load Balancer Controller using Helm
echo "Adding Helm repo and installing AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$REGION \
  --set vpcId=$VPC_ID \
  --set image.repository=602401143452.dkr.ecr.$REGION.amazonaws.com/amazon/aws-load-balancer-controller

# Step 6: Verify ALB Controller installation
echo "Verifying ALB Controller installation..."
kubectl get deployment -n kube-system aws-load-balancer-controller

echo "AWS Load Balancer Controller setup complete."
