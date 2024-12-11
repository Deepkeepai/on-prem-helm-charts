### Pre-Requisites Check for DeepKeep Deployment

This document outlines how to use the `check_prerequisites.sh` script to ensure that all necessary requirements are met before deploying the DeepKeep Helm chart.

---

## Purpose

The `check_prerequisites.sh` script verifies the following:
- Required tools (`kubectl`, `helm`, `aws`) are installed.
- Kubernetes cluster connectivity is established.
- The Kubernetes cluster meets version and configuration requirements.
- Necessary namespaces and secrets are set up.
- Persistent storage support is available.
- Amazon ECR authentication is configured (if required).

Running this script helps prevent deployment failures due to missing or misconfigured prerequisites.

---

## Usage Instructions

### Step 1: Download the Script
Save the `check_prerequisites.sh` script to your local machine.

### Step 2: Make the Script Executable
Run the following command to make the script executable:
```bash
chmod +x check_prerequisites.sh
```

### Step 3: Execute the Script
Run the script to verify prerequisites:
```bash
./check_prerequisites.sh
```

### Step 4: Address Any Errors
If the script identifies any issues, follow the provided instructions to resolve them. After addressing the issues, re-run the script to ensure all checks pass.

---

## Checks Performed

1. **Tool Availability**:
   - Verifies that the following commands are available:
     - `kubectl`
     - `helm`
     - `aws` (optional, for ECR authentication)
   - Prints an error and exits if any of these tools are missing.

2. **Kubernetes Cluster Connectivity**:
   - Ensures `kubectl` can communicate with the Kubernetes cluster.
   - Prints an error if connectivity cannot be established.

3. **Helm and Kubernetes Versions**:
   - Checks the installed Helm version and the Kubernetes server version.
   - Ensures the Kubernetes version is `v1.20` or newer.

4. **Namespace Setup**:
   - Checks for the existence of the `deepkeep` namespace.
   - Creates the namespace if it doesn’t already exist.

5. **License Secret**:
   - Verifies that the `license-secret` exists in the `deepkeep` namespace.
   - Provides instructions to create the secret if it is missing.

6. **Helm Dependencies**:
   - Ensures Helm dependencies listed in `Chart.yaml` are resolved.

7. **Node Readiness**:
   - Confirms that at least one Kubernetes node is in the `Ready` state.

8. **Persistent Storage Support**:
   - Checks for support for Persistent Volumes (PV) and Persistent Volume Claims (PVC).

9. **Amazon ECR Authentication** (Optional):
   - If ECR authentication is required, verifies that AWS CLI is configured and able to authenticate with ECR.

---

## Example Output

### Success
```plaintext
Checking required commands...
All required commands are installed.
Checking Kubernetes cluster connectivity...
Connected to Kubernetes cluster.
Checking Helm version...
Helm version: v3.11.2
Checking Kubernetes version...
Kubernetes version: v1.26.3
Checking if namespace 'deepkeep' exists...
Namespace 'deepkeep' exists.
Checking for license secret...
License secret found.
Checking Helm dependencies...
Helm dependencies are up to date.
Checking if nodes are ready...
3 node(s) are ready.
Checking for Persistent Volume (PV) and Persistent Volume Claim (PVC) support...
Persistent storage support is available.
All prerequisites are satisfied. You can now proceed with the installation.
```

### Error
```plaintext
Checking for license secret...
Error: License secret 'license-secret' does not exist in namespace 'deepkeep'.
Create it using the following command:
kubectl create secret generic license-secret --from-literal=licenseKey=<your-license-key> -n deepkeep
```

---

## Next Steps

After resolving any reported issues and confirming that all checks pass:
1. Proceed with the deployment of the Helm chart:
   ```bash
   helm upgrade --install deepkeep ./helm-chart --namespace deepkeep
   ```
2. Verify that the application is running as expected:
   ```bash
   kubectl get pods --namespace deepkeep
   ```

---

## Troubleshooting

If you encounter issues while running the script:
- Ensure `kubectl` is configured to communicate with the correct cluster (`kubectl config current-context`).
- Verify that the necessary permissions are granted to your user or role.
- Check the script for any configuration mismatches with your setup.

---
