#!/bin/bash

# Prompt user for input
read -p "Enter the EKS cluster name: " CLUSTER_NAME
read -p "Enter the AWS region for the cluster: " REGION
read -p "Enter the zones (comma-separated, e.g., us-east-1a,us-east-1b): " ZONES
read -p "Enter the SSH public key name (e.g., kube-demo): " SSH_KEY
read -p "Enter the node group name: " NODEGROUP_NAME
read -p "Enter the node type (e.g., t3.medium): " NODE_TYPE
read -p "Enter the desired number of nodes: " NODES
read -p "Enter the minimum number of nodes: " NODES_MIN
read -p "Enter the maximum number of nodes: " NODES_MAX
read -p "Enter the node volume size (in GB): " VOLUME_SIZE

# Create EKS cluster without node group
eksctl create cluster --name="$CLUSTER_NAME" \
                      --region="$REGION" \
                      --zones="$ZONES" \
                      --without-nodegroup

# Associate IAM OIDC provider
eksctl utils associate-iam-oidc-provider \
    --region "$REGION" \
    --cluster "$CLUSTER_NAME" \
    --approve

# Create node group with the specified parameters
eksctl create nodegroup --cluster="$CLUSTER_NAME" \
                       --region="$REGION" \
                       --name="$NODEGROUP_NAME" \
                       --node-type="$NODE_TYPE" \
                       --nodes="$NODES" \
                       --nodes-min="$NODES_MIN" \
                       --nodes-max="$NODES_MAX" \
                       --node-volume-size="$VOLUME_SIZE" \
                       --ssh-access \
                       --ssh-public-key="$SSH_KEY" \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --alb-ingress-access

echo "EKS cluster and node group creation initiated."

