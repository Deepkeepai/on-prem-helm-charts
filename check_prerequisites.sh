#!/usr/bin/env bash

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it before proceeding."
        exit 1
    fi
}

# Check for required commands
echo -n "===> Checking required commands..."
check_command kubectl
check_command helm
check_command aws  # For ECR authentication, if needed
echo "All required commands are installed."

# Check Kubernetes cluster connectivity
echo -n "===> Checking Kubernetes cluster connectivity..."
if ! kubectl version &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster. Ensure 'kubectl' is configured correctly."
    exit 1
fi
echo "Connected to Kubernetes cluster."

# Check Kubernetes version
echo -n "===> Checking Kubernetes version..."
KUBE_VERSION=$(kubectl version | awk '/^Server/{print $3}' | cut -d- -f1)
if [[ "$KUBE_VERSION" < "v1.28" ]]; then
    echo "Error: Kubernetes version $KUBE_VERSION is too old. v1.28 or newer is required."
    exit 1
fi
echo "Kubernetes version: $KUBE_VERSION"

# Check Helm version
echo -n "===> Checking Helm version..."
HELM_VERSION=$(helm version --short)
if [[ -z "$HELM_VERSION" ]]; then
    echo "Error: Helm is not configured correctly."
    exit 1
fi
echo "Helm version: $HELM_VERSION"

# Check namespace
NAMESPACE="deepkeep"
echo -n "===> Checking if namespace '$NAMESPACE' exists..."
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Namespace '$NAMESPACE' does not exist. Creating it now..."
    kubectl create namespace "$NAMESPACE"
else
    echo "Namespace '$NAMESPACE' exists."
fi

# Check for license secret
echo -n "===> Checking for license secret..."
if ! kubectl get secret license-secret -n "$NAMESPACE" &> /dev/null; then
    echo "Error: License secret 'license-secret' does not exist in namespace '$NAMESPACE'."
    echo "Create it using the following command:"
    echo "kubectl create secret generic license-secret --from-literal=licenseKey=<your-license-key> -n $NAMESPACE"
    exit 1
fi
echo "License secret found."

# Check cluster hardware requirements
echo -n "===> Checking cluster hardware requirements..."
TOTAL_CPUS=$(kubectl get nodes -o json | jq '[.items[].status.allocatable.cpu] | map((gsub("m";"") | tonumber)) | add')
if [[ "$TOTAL_CPUS" -lt 16000 ]]; then
    echo "Error: Insufficient CPUs. 16 CPUs are required, but only $TOTAL_CPUS are available."
    exit 1
fi
# echo "CPU availbale: ${TOTAL_CPUS}m"

TOTAL_MEMORY=$(kubectl get nodes -o json | jq '[.items[].status.allocatable.memory] | map(gsub("Ki"; "") | tonumber) | add')
if [[ "$TOTAL_MEMORY" -lt 134217728 ]]; then  # Convert 128GB to KiB
    echo "Error: Insufficient memory. 128 GB is required, but only $((TOTAL_MEMORY / 1024 / 1024)) GB are available."
    exit 1
fi
# echo "RAM availbale: ${TOTAL_MEMORY}Ki"
echo "Cluster hardware requirements are satisfied."

# Check for Persistent Volume (PV) and Persistent Volume Claim (PVC) support
echo -n "===> Checking for Persistent Volume (PV) and Persistent Volume Claim (PVC) support..."
PV_SUPPORT=$(kubectl api-resources | grep -c "persistentvolumes")
PVC_SUPPORT=$(kubectl api-resources | grep -c "persistentvolumeclaims")
if [[ "$PV_SUPPORT" -eq 0 || "$PVC_SUPPORT" -eq 0 ]]; then
    echo "Error: Persistent storage is not supported in this cluster."
    exit 1
fi
echo "Persistent storage support is available."

# Check GPU requirements (optional)
echo -n "===> Checking for GPU nodes (optional)..."
GPU_NODES=$(kubectl get nodes -o json | jq '[.items[] | select(.status.allocatable."nvidia.com/gpu")] | length')
if [[ "$GPU_NODES" -eq 0 ]]; then
    echo "Warning: No GPU nodes detected. Ensure GPUs are available if required for assessments or firewalls."
else
    echo "GPU nodes detected: $GPU_NODES"
fi

# Check ECR authentication (if using ECR)
if grep -q "ecr-auth" values.yaml; then
    echo -n "===> Checking ECR authentication..."
    if ! aws ecr get-login-password --region ${AWS_REGION:-eu-central-1} &> /dev/null; then
        echo "Error: ECR authentication failed. Ensure AWS CLI is configured and has appropriate permissions."
        exit 1
    fi
    echo "ECR authentication successful."
fi

# Final readiness check
echo "All prerequisites are satisfied. You can now proceed with the installation."
exit 0
