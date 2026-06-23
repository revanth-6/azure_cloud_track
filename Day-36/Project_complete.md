# DocBridge Platform Operational Runbook & Cheatsheet

This runbook contains the complete operational instructions, step-by-step procedures, and reference configurations for the **DocBridge** platform. All resource names, IDs, paths, and commands are specific to the actual environment configuration.

---

## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 1: PREREQUISITES & ONE-TIME SETUP
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 1.1 Tools to Install
Install the following core DevOps tools required to manage the infrastructure, build pipelines, and cluster workloads.

| Tool Name | Target Version | Install Command (Windows - winget/choco) | Install Command (Mac - brew) | Install Command (Linux - apt) | Verification Command |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Azure CLI (az)** | `2.60.0+` | `winget install Microsoft.AzureCLI` | `brew install azure-cli` | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` | `az --version` |
| **Terraform** | `1.5.7` | `choco install terraform --version=1.5.7` | `brew install hashicorp/tap/terraform@1.5.7` | Download zip from Hashicorp portal and map to `/usr/local/bin` | `terraform --version` |
| **Kubectl** | `1.30+` | `winget install Kubernetes.kubectl` | `brew install kubectl` | `sudo apt-get update && sudo apt-get install -y kubectl` | `kubectl version --client` |
| **Helm** | `3.12+` | `choco install kubernetes-helm` | `brew install helm` | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` | `helm version` |
| **Docker** | `24.0+` | Install Docker Desktop | Install Docker Desktop | `sudo apt-get install -y docker.io` | `docker --version` |
| **Git** | `2.40+` | `winget install Git.Git` | `brew install git` | `sudo apt install git` | `git --version` |
| **GitHub CLI (gh)** | `2.30+` | `winget install GitHub.cli` | `brew install gh` | `sudo apt install gh` | `gh --version` |
| **Trivy** | `0.45.0+` | `choco install trivy` | `brew install aquasecurity/trivy/trivy` | Add aquasecurity repo & run `sudo apt install trivy` | `trivy --version` |
| **yq** | `4.34+` | `choco install yq` | `brew install yq` | `sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq` | `yq --version` |

---

### 1.2 Azure CLI Login & Setup
Run these commands locally to authenticate and set default scopes for the project:

```bash
# Login to Azure
az login

# Set active subscription ID
az account set --subscription "f1808c66-ab07-46b3-bb93-06c6f2f406dc"

# Verify active subscription
az account show

# Configure default resource group
az configure --defaults group=docbridge-rg
```

---

### 1.3 GitHub Secrets Setup
Ensure all required OIDC, SMTP, and application variables are created inside the GitHub repository settings.

#### DocBridge-terraform secrets:
```bash
# Set OIDC Client ID
gh secret set AZURE_CLIENT_ID --body "f20c8a93-cb30-4391-b59e-796a90c4f936" --repo Docbridge-devops-project/DocBridge-terraform

# Set Azure Tenant ID
gh secret set AZURE_TENANT_ID --body "ffdb5413-63c8-40ec-a158-c5ad34880e3d" --repo Docbridge-devops-project/DocBridge-terraform

# Set Azure Subscription ID
gh secret set AZURE_SUBSCRIPTION_ID --body "f1808c66-ab07-46b3-bb93-06c6f2f406dc" --repo Docbridge-devops-project/DocBridge-terraform

# Set TF State Storage Account Name
gh secret set TF_STORAGE_ACCOUNT_NAME --body "docbridgestate849310" --repo Docbridge-devops-project/DocBridge-terraform

# Set TF State Storage Container Name
gh secret set TF_CONTAINER_NAME --body "tfstate" --repo Docbridge-devops-project/DocBridge-terraform

# Set Alert destination email
gh secret set ALERT_EMAIL --body "arjun.mehta@gmail.com" --repo Docbridge-devops-project/DocBridge-terraform

# Set PostgreSQL Database password
gh secret set DB_PASSWORD --body "P@ssw0rdSecureDB!23" --repo Docbridge-devops-project/DocBridge-terraform

# Set JWT Access token secret
gh secret set JWT_ACCESS_SECRET --body "your-base64-access-token-secret-key" --repo Docbridge-devops-project/DocBridge-terraform

# Set JWT Refresh token secret
gh secret set JWT_REFRESH_SECRET --body "your-base64-refresh-token-secret-key" --repo Docbridge-devops-project/DocBridge-terraform

# Set Azure OpenAI key
gh secret set AZURE_OPENAI_KEY --body "your-azure-openai-cognitive-services-key" --repo Docbridge-devops-project/DocBridge-terraform

# Set SMTP notification credentials
gh secret set SMTP_USERNAME --body "alert.sender@gmail.com" --repo Docbridge-devops-project/DocBridge-terraform
gh secret set SMTP_PASSWORD --body "gmail-app-password" --repo Docbridge-devops-project/DocBridge-terraform
```

#### DocBridge-application secrets:
```bash
# Set OIDC Client ID
gh secret set AZURE_CLIENT_ID --body "f20c8a93-cb30-4391-b59e-796a90c4f936" --repo Docbridge-devops-project/DocBridge-application

# Set Azure Tenant ID
gh secret set AZURE_TENANT_ID --body "ffdb5413-63c8-40ec-a158-c5ad34880e3d" --repo Docbridge-devops-project/DocBridge-application

# Set Azure Subscription ID
gh secret set AZURE_SUBSCRIPTION_ID --body "f1808c66-ab07-46b3-bb93-06c6f2f406dc" --repo Docbridge-devops-project/DocBridge-application

# Set TF State Storage Account Name
gh secret set TF_STORAGE_ACCOUNT_NAME --body "docbridgestate849310" --repo Docbridge-devops-project/DocBridge-application

# Set TF State Storage Container Name
gh secret set TF_CONTAINER_NAME --body "tfstate" --repo Docbridge-devops-project/DocBridge-application

# Set Alert destination email
gh secret set ALERT_EMAIL --body "arjun.mehta@gmail.com" --repo Docbridge-devops-project/DocBridge-application

# Set SMTP notification credentials
gh secret set SMTP_USERNAME --body "alert.sender@gmail.com" --repo Docbridge-devops-project/DocBridge-application
gh secret set SMTP_PASSWORD --body "gmail-app-password" --repo Docbridge-devops-project/DocBridge-application

# Set Snyk SCA token
gh secret set SNYK_TOKEN --body "your-snyk-api-token" --repo Docbridge-devops-project/DocBridge-application

# Set SonarCloud token & org
gh secret set SONAR_TOKEN --body "your-sonarcloud-token" --repo Docbridge-devops-project/DocBridge-application
gh secret set SONAR_ORGANIZATION --body "docbridge-devops-project" --repo Docbridge-devops-project/DocBridge-application

# Set Kubernetes git write PAT
gh secret set KUBERNETES_REPO_PAT --body "ghp_PersonalAccessTokenWithWriteAccess" --repo Docbridge-devops-project/DocBridge-application
```

---

### 1.4 GitHub Environments Setup
The `production` environment must be configured inside both repositories to authorize manual approval loops for production deploys.

#### Via GitHub CLI:
```bash
gh api repos/Docbridge-devops-project/DocBridge-application/environments/production --method PUT --field wait_timer=0
gh api repos/Docbridge-devops-project/DocBridge-terraform/environments/production --method PUT --field wait_timer=0
```

#### Via GitHub UI:
1. Open the repository on GitHub (`DocBridge-application` or `DocBridge-terraform`).
2. Go to **Settings** → **Environments**.
3. Select the **production** environment.
4. Check **Required reviewers**.
5. Add the approval usernames (e.g., `ArjunMehta` or team reviewers).
6. Click **Save protection rules**.

---

### 1.5 Azure Service Principal for GitHub Actions
Register an App ID in Azure AD, configure Federated Credentials, and assign subscriptions to enable passwordless authentication (OIDC).

```bash
# Create service principal with Contributor rights on subscription
az ad sp create-for-rbac \
  --name "DocBridge-DevOps" \
  --role contributor \
  --scopes /subscriptions/f1808c66-ab07-46b3-bb93-06c6f2f406dc \
  --sdk-auth

# Get Application Object ID
APP_OBJECT_ID=$(az ad app show --id "f20c8a93-cb30-4391-b59e-796a90c4f936" --query id -o tsv)

# Create OIDC Federated Credential for Application repo (main branch)
az ad app federated-credential create --id $APP_OBJECT_ID --parameters '{
  "name": "docbridge-app-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:Docbridge-devops-project/DocBridge-application:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Create OIDC Federated Credential for Application repo (develop branch)
az ad app federated-credential create --id $APP_OBJECT_ID --parameters '{
  "name": "docbridge-app-dev",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:Docbridge-devops-project/DocBridge-application:ref:refs/heads/develop",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Create OIDC Federated Credential for Terraform repo (main branch)
az ad app federated-credential create --id $APP_OBJECT_ID --parameters '{
  "name": "docbridge-tf-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:Docbridge-devops-project/DocBridge-terraform:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Assign AcrPush role to service principal on ACR
az role assignment create \
  --assignee "f20c8a93-cb30-4391-b59e-796a90c4f936" \
  --role "AcrPush" \
  --scope /subscriptions/f1808c66-ab07-46b3-bb93-06c6f2f406dc/resourceGroups/docbridge-rg/providers/Microsoft.ContainerRegistry/registries/docbridgedevacr

# Assign AKS Admin role to service principal on Cluster
az role assignment create \
  --assignee "f20c8a93-cb30-4391-b59e-796a90c4f936" \
  --role "Azure Kubernetes Service Cluster Admin Role" \
  --scope /subscriptions/f1808c66-ab07-46b3-bb93-06c6f2f406dc/resourceGroups/docbridge-rg/providers/Microsoft.ContainerService/managedClusters/docbridge-dev-aks
```

---

## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 2: TERRAFORM — FULL SETUP & RUN GUIDE
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 2.1 Terraform Backend Setup
A remote backend storage account is used to cache the state files. Run these bootstrap commands once before deploying the infrastructure:

```bash
# Create State resource group
az group create --name docbridge-rg --location centralus

# Create State storage account (standard, hot, private)
az storage account create \
  --name docbridgestate849310 \
  --resource-group docbridge-rg \
  --location centralus \
  --sku Standard_LRS \
  --encryption-services blob

# Create Storage container
az storage container create \
  --name tfstate \
  --account-name docbridgestate849310
```

---

### 2.2 Terraform Directory Structure
The structure of the `DocBridge-terraform/terraform` directory is outlined below:

* [providers.tf](file:///c:/Users/admin/Downloads/devops_final/DocBridge-terraform/terraform/providers.tf) - Defines provider versions (`azurerm`, `azuread`, `tls`, `time`) and empty remote backend declarations.
* [variables.tf](file:///c:/Users/admin/Downloads/devops_final/DocBridge-terraform/terraform/variables.tf) - Variable declarations (sizing, subscription, regional parameters).
* [terraform.tfvars](file:///c:/Users/admin/Downloads/devops_final/DocBridge-terraform/terraform/terraform.tfvars) - Default values for variables (Owner `ArjunMehta`, Environment `dev`, Location `centralus`).
* [bastion_vm.tf](file:///c:/Users/admin/Downloads/devops_final/DocBridge-terraform/terraform/bastion_vm.tf) - Configures the `Standard` Azure Bastion Host, management VM NIC, OS disk, SSH private key generation, and exports SSH private key into Key Vault.
* [main.tf](file:///c:/Users/admin/Downloads/devops_final/DocBridge-terraform/terraform/main.tf) - Root orchestrator module invoking standard child modules.
* [outputs.tf](file:///c:/Users/admin/Downloads/devops_final/DocBridge-terraform/terraform/outputs.tf) - Generates outputs after apply, including key vault names, workload identity Client ID, Cost Estimates, and IP maps.
* `modules/` - Child modules grouping resources:
  * `networking` - Provisions standard VNet, Subnets (AKS, Gateway, Database, Bastion), NSGs, and peering settings.
  * `storage` - App store and temporary diagnostics container.
  * `monitoring` - Provisions Log Analytics workspace, Application Insights, Web Ping Tests, and Alerts (`v2` alerts query rules with OIDC-compliant endpoints).
  * `acr` - Azure Container Registry (`docbridgedevacr.azurecr.io`).
  * `keyvault` - Handles Key Vault provisioning (`docbridge-dev-kv`) and mounts access control list overrides.
  * `servicebus` - Service Bus namespaces and queue pools.
  * `database` - Private flexible PostgreSQL server (`docbridge-dev-postgres-c`) and schema maps.
  * `appgateway` - Application Gateway (`docbridge-dev-appgw`), WAF policy configurations, rules, and backend HTTP definitions.
  * `aks` - Configures Standard AKS cluster (`docbridge-dev-aks`), OIDC credentials, system node pools, user node pools, dynamic ingress parameters, and matches role definitions.
  * `security` - Attaches locks to protect resource deletions.

---

### 2.3 Running Terraform Locally

```bash
# Step 1: Navigate to directory
cd DocBridge-terraform/terraform

# Step 2: Initialize remote backend
terraform init \
  -backend-config="resource_group_name=docbridge-rg" \
  -backend-config="storage_account_name=docbridgestate849310" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.terraform.tfstate"

# Step 3: Validate syntax
terraform validate

# Step 4: Check format
terraform fmt -check -recursive
# (Fix layout if checks fail: terraform fmt -recursive)

# Step 5: Generate execution plan (referencing sensitive parameters)
terraform plan -var-file="secrets.tfvars" -out=tfplan

# Step 6: Apply changes
terraform apply tfplan
```

---

### 2.4 Running Terraform by Module
To execute plans or applies target-specifically (e.g., during troubleshooting/modifications):

```bash
# Plan only networking
terraform plan -target=module.networking -var-file="secrets.tfvars"

# Apply only keyvault
terraform apply -target=module.keyvault -var-file="secrets.tfvars" -auto-approve
```

#### Modules list:
* `module.networking`
* `module.storage`
* `module.monitoring`
* `module.acr`
* `module.keyvault`
* `module.servicebus`
* `module.database`
* `module.appgateway`
* `module.aks`
* `module.security`

---

### 2.5 Triggering Terraform Pipeline (GitHub Actions)
The infrastructure pipeline triggers automatically on any merge request or push modifying the `terraform/**` folder:

```bash
# Trigger manually via GitHub CLI
gh workflow run terraform-apply.yml \
  --repo Docbridge-devops-project/DocBridge-terraform \
  -f action=apply

# Watch pipeline run live
gh run watch --repo Docbridge-devops-project/DocBridge-terraform

# View run logs
gh run view --log --repo Docbridge-devops-project/DocBridge-terraform
```

---

### 2.6 Approving Terraform Pipeline
1. Navigate to the pipeline run under **Actions** inside the GitHub UI.
2. Select the running workflow `Terraform Infrastructure Pipeline`.
3. Locate the approval banner on the `production` environment deployment stage.
4. Click **Review deployments**, check the approval checkbox, and click **Approve and deploy**.

Or approve via CLI:
```bash
gh run approve [RUN_ID] --repo Docbridge-devops-project/DocBridge-terraform
```

---

### 2.7 Terraform State Commands
```bash
# List all tracked resources
terraform state list

# View resource configurations
terraform state show module.aks.azurerm_kubernetes_cluster.main

# Unlock a hung workspace state (retrieve Lock ID from console error logs)
terraform force-unlock [LOCK_ID]

# Remove resource from state file (without deleting cloud instance)
terraform state rm module.security.azurerm_management_lock.rg_lock

# Import manual resources into state configuration
terraform import module.database.azurerm_postgresql_flexible_server.main /subscriptions/f1808c66-ab07-46b3-bb93-06c6f2f406dc/resourceGroups/docbridge-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/docbridge-dev-postgres-c
```

---

## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 3: BUILD PIPELINE — FULL TRIGGER & RUN GUIDE
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 3.1 What Triggers the Build Pipeline
* **Automatic Triggers**: Any push to `main` or `develop` branch, or pull requests to `main` containing changes under path patterns: `services/**`, `gateway/**`, `frontend/**`, and `database/**`.
* **Manual Triggers**: Can be fired manually using the `workflow_dispatch` trigger options to build specific services.

---

### 3.2 Triggering Build Pipeline
```bash
# Trigger build pipeline manually (forces full build and scans across all 11 services)
gh workflow run build.yml --repo Docbridge-devops-project/DocBridge-application
```

---

### 3.3 Monitoring Build Pipeline
```bash
# List last 10 build runs
gh run list --repo Docbridge-devops-project/DocBridge-application --workflow=build.yml --limit 10

# Watch running job status live
gh run watch --repo Docbridge-devops-project/DocBridge-application

# Check logs of a specific build run ID
gh run view [RUN_ID] --log --repo Docbridge-devops-project/DocBridge-application
```

---

### 3.4 Build Stages and Verification

#### 1. Job: `detect-changes`
* **What it does**: Inspects git directories and runs a helper script compiling changes. Forces outputs `changed_services` list mapping all 11 microservices.
* **Success Indicator**: Prints `Forced changed services: ["frontend","api-gateway",...]`.

#### 2. Job: `cicd-db-migrations`
* **What it does**: Builds docker container in database folder, runs Trivy scan, and tags/pushes `db-migrations` to ACR.
* **Success Indicator**: Logs show `Pushing Image to ACR: docbridgedevacr.azurecr.io/db-migrations:latest`.

#### 3. Job: `cicd-[service-name]-sonar` (e.g. `cicd-api-gateway-sonar`)
* **What it does**: Bypassed on `frontend`. Runs static SAST quality check inside SonarCloud (ignores coverage properties).
* **Success Indicator**: `QUALITY GATE STATUS: PASSED` in Sonar logs.

#### 4. Job: `cicd-[service-name]-build` (e.g. `cicd-auth-service-build`)
* **What it does**: Runs `npm ci`, compiles application binaries, and invokes Snyk SCA checking node dependencies.
* **Success Indicator**: Generates `snyk-results.html` and uploads reports as GitHub workflow artifacts.

#### 5. Job: `cicd-[service-name]-docker` (e.g. `cicd-labreport-service-docker`)
* **What it does**: Logs in to Azure registry, compiles code into docker container, runs Trivy scanning OS-level files (ignores accepted CVEs from `.trivyignore`), and pushes short SHA tagged images to ACR.
* **Success Indicator**: Logs display push logs to `docbridgedevacr.azurecr.io/labreport-service:[short-sha]`.

---

### 3.5 Verifying Build Success
```bash
# Verify image repositories are updated in ACR
az acr repository list --name docbridgedevacr --output table

# Verify image tags exist for a target service
az acr repository show-tags --name docbridgedevacr --repository api-gateway --orderby time_desc --output table
```

---

## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 4: DEPLOY PIPELINE — FULL TRIGGER & RUN GUIDE
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 4.1 What Triggers the Deploy Pipeline
* **Automatic Triggers**: Runs on completion of `DocBridge Build Pipeline` on the `main` branch with status `success`.
* **Manual Triggers**: Can be executed manually via the `workflow_dispatch` trigger.

---

### 4.2 Triggering Deploy Pipeline
```bash
# Manually trigger deploy pipeline
gh workflow run deploy.yml --repo Docbridge-devops-project/DocBridge-application
```

---

### 4.3 Connecting to AKS (Manually)
Since the AKS API server is private, local client CLI execution requires connecting from the VM:
```bash
# 1. Download SSH private key from Key Vault
az keyvault secret download --vault-name docbridge-dev-kv --name mgmt-vm-ssh-private-key --file id_rsa --overwrite

# 2. Configure file permissions (Windows PowerShell)
icacls.exe id_rsa /inheritance:r /grant:r "${env:USERNAME}:(R)"
# (For Linux/Mac: chmod 400 id_rsa)

# 3. Tunnel to Private Management VM via Bastion
az network bastion ssh \
  --name docbridge-dev-bastion \
  --resource-group docbridge-rg \
  --target-resource-id /subscriptions/f1808c66-ab07-46b3-bb93-06c6f2f406dc/resourceGroups/docbridge-rg/providers/Microsoft.Compute/virtualMachines/docbridge-dev-mgmt-vm \
  --auth-type ssh-key \
  --username adminuser \
  --ssh-key id_rsa

# 4. Fetch AKS credentials inside VM
az aks get-credentials --resource-group docbridge-rg --name docbridge-dev-aks --overwrite-existing

# 5. Verify connectivity
kubectl get nodes -o wide
```

---

### 4.4 Deploy Pipeline Steps

#### 1. Job: `setup`
* **What it does**: Initializes Terraform inside pipeline runner, gets state parameters, resolves Key Vault and AppGW properties, and determines the image tag to deploy.
* **Success Indicator**: Outputs resolved workload identity `identity_id` and PostgreSQL flexible host FQDN.

#### 2. Job: `approve`
* **What it does**: Holds deployment execution for manual review.
* **Success Indicator**: Reviewer clicks "Approve" inside Action workflows.

#### 3. Job: `deploy` (GitOps Promote)
* **What it does**: Checks out the `DocBridge-kubernetes` repository. Uses `yq` to replace active configurations (KeyVault name, identity client ID, DB host, AppGW public IP, and docker image tags) inside `argocd/application.yaml`. Commits and pushes changes to git repository.
* **Success Indicator**: Git commit `chore(deploy): promote image to [short-sha] [skip ci]` pushed to main branch.

#### 4. Job: `verify-and-smoke-test`
* **What it does**: Pauses for 90 seconds to allow Argo CD to synchronize. Runs a loop of 20 retry checks against the public Application Gateway IP health endpoints.
* **Success Indicator**: Logs output `HTTP Responses - /healthz: 200, /ready: 200, Smoke tests passed!`.

---

### 4.5 Verifying Deploy Success
From inside the management VM:
```bash
# Check pod rollout status in production
kubectl get pods -n production

# Check rollout progress
kubectl rollout status deployment/frontend -n production

# Verify Ingress routing IP
kubectl get ingress -n production
```

---

## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 5: KUBERNETES — FULL SETUP & RUN GUIDE
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 5.1 Connecting to the Cluster
(Perform inside the management VM after logging in via Bastion native SSH client):
```bash
# Set credentials
az aks get-credentials --resource-group docbridge-rg --name docbridge-dev-aks --overwrite-existing

# Check cluster info
kubectl cluster-info
```

---

### 5.2 Bootstrapping Argo CD (GitOps)
If the cluster is fresh/re-created, run these commands inside the management VM to install and bootstrap Argo CD:

```bash
# Create namespace
kubectl create namespace argocd

# Add and install Argo CD charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values ./docbridge-kubernetes/argocd/install/values.yaml

# Retrieve admin dashboard password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
# Note: Initial password in dev environment is configured as: DKmA6-r7wmlnRl0Z

# Apply project boundaries and application sync definition
kubectl apply -f ./docbridge-kubernetes/argocd/project.yaml
kubectl apply -f ./docbridge-kubernetes/argocd/application.yaml
```

---

### 5.3 Accessing the Argo CD Dashboard
To open the Argo CD Web UI from your local computer:

1. **Step 1**: Start a Bastion native SSH tunnel from your local terminal with local port forwarding enabled:
   ```bash
   az network bastion ssh \
     --name docbridge-dev-bastion \
     --resource-group docbridge-rg \
     --target-resource-id /subscriptions/f1808c66-ab07-46b3-bb93-06c6f2f406dc/resourceGroups/docbridge-rg/providers/Microsoft.Compute/virtualMachines/docbridge-dev-mgmt-vm \
     --auth-type ssh-key \
     --username adminuser \
     --ssh-key id_rsa \
     -- -L 8080:127.0.0.1:8080
   ```
2. **Step 2**: Inside the SSH terminal session on the management VM, start a `kubectl port-forward` to the Argo CD server:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:80
   ```
3. **Step 3**: On your local computer, open your web browser and navigate to:
   **`http://localhost:8080`**
4. **Step 4**: Sign in using credentials:
   - **Username**: `admin`
   - **Password**: `DKmA6-r7wmlnRl0Z`

---

### 5.4 Checking Application Deployment Status
Inside the management VM, run:
```bash
# Verify namespace
kubectl get namespaces

# Check all pods status
kubectl get pods -n production

# Check endpoints mapped to services
kubectl get endpoints -n production

# Watch rollout logs of specific app deployments
kubectl logs deployment/api-gateway -n production -c api-gateway --tail=100
```

---

## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 6: DEBUGGING — SPECIFIC TO THIS PROJECT
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 6.1 Actual Failures Faced & Resolved

#### 1. ERROR: `502 Bad Gateway` after namespace deletions / Helm conflicts
* **Where**: Smoke tests / Public access endpoint (`http://20.118.10.38/`).
* **Root Cause**: Wiping and re-creating the `production` namespace deleted the dynamic ingress configuration. The Application Gateway Ingress Controller (AGIC) pod did not reconcile properly, leaving the App Gateway backend pools empty.
* **Fix**: Force a restart of the AGIC pod to reload cache:
  ```bash
  kubectl rollout restart deployment ingress-appgw-deployment -n kube-system
  ```

#### 2. ERROR: Terraform Apply deletes AGIC configurations during pipeline runs
* **Where**: Infrastructure pipeline execution (`terraform-apply.yml`).
* **Root Cause**: AGIC makes dynamic configuration changes in Azure (e.g., creating WAF rules, target backend IP mappings). When Terraform ran, it detected these as state drifts and removed them, causing `502 Bad Gateway` errors.
* **Fix**: Added a `lifecycle { ignore_changes = [...] }` rule to `azurerm_application_gateway.main` to ignore AGIC-managed properties:
  ```hcl
  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      url_path_map,
      probe,
      ssl_certificate,
      tags
    ]
  }
  ```

#### 3. ERROR: AGIC Stuck crashing in `CrashLoopBackOff` with `403 Forbidden`
* **Where**: AGIC controller logs.
* **Root Cause**: The Terraform `azurerm` provider's cluster property `ingress_application_gateway_identity[0].object_id` returns the **Client ID** of the user-assigned identity, not the **Object (Principal) ID**. Thus, roles were assigned to an invalid identity.
* **Fix**: Resolved the correct `principal_id` dynamically using:
  ```hcl
  data "azurerm_user_assigned_identity" "agic" {
    name                = "ingressapplicationgateway-${var.project}-${var.environment}-aks"
    resource_group_name = "MC_${var.project}-rg_${var.project}-${var.environment}-aks_${var.location}"
  }
  ```
  And bound the `Reader`, `Contributor`, and `Network Contributor` roles using `data.azurerm_user_assigned_identity.agic.principal_id` (Value: `3dc98e6e-1b1e-4c0a-b75b-11d5a1d3262f`).

#### 4. ERROR: Monitor Alert creation fails with `BadRequest: Insufficient Access`
* **Where**: Terraform creation of Scheduled Query Rules.
* **Root Cause**: Azure AD role assignments take up to 60-90 seconds to propagate across resource groups. Deploying alerts query rules immediately after assigning roles resulted in replication latency failures.
* **Fix**: Added a `time_sleep` resource (`wait_role_propagation`) of 90 seconds. All scheduled alert queries now depend on this sleep resource.

#### 5. ERROR: Bastion native SSH tunnel fails with `Connection reset`
* **Where**: CLI connection from local client to VM.
* **Root Cause**: Bastion was configured with the `Basic` SKU (which does not support native tunneling) and the management subnet NSG was blocking SSH traffic.
* **Fix**: Upgraded Bastion SKU to `Standard`, set `tunneling_enabled = true` in `bastion_vm.tf`, and added an inbound NSG rule `AllowSSHFromBastion` (priority 110) in `modules/networking/main.tf` to allow TCP/22 from the Bastion subnet (`10.0.5.0/26`).

#### 6. ERROR: Scheduled Query Rules fail to deploy due to legacy APIs under OIDC
* **Where**: Monitoring alert configurations.
* **Root Cause**: The legacy `azurerm_monitor_scheduled_query_rules_alert` resource uses the older `2018-04-16` API, which fails to authenticate when pipelines run under OIDC federated credentials.
* **Fix**: Migrated to the modern `azurerm_monitor_scheduled_query_rules_alert_v2` resource, and set `skip_query_validation = true` to bypass verification checks before tables are created in Log Analytics.

---

### 6.2 Common Kubernetes Troubleshooting Commands

#### Pod stuck in `ImagePullBackOff` or `ErrImagePull`
Check ACR credentials and ensure AKS has permissions to pull.
```bash
# 1. Inspect pod events
kubectl describe pod [POD_NAME] -n production

# 2. Check if the image exists in ACR
az acr repository show-tags --name docbridgedevacr --repository api-gateway

# 3. Grant AcrPull manually if missing
az role assignment create \
  --assignee "aks-kubelet-identity-principal-id" \
  --role "AcrPull" \
  --scope /subscriptions/f1808c66-ab07-46b3-bb93-06c6f2f406dc/resourceGroups/docbridge-rg/providers/Microsoft.ContainerRegistry/registries/docbridgedevacr
```

#### Pod stuck in `CrashLoopBackOff`
Check application startup configurations and secrets.
```bash
# 1. Fetch live logs
kubectl logs [POD_NAME] -n production

# 2. Fetch logs from previous failed container instance
kubectl logs [POD_NAME] -n production --previous

# 3. Inspect mounted configs and secrets
kubectl get configmap docbridge-config -n production -o yaml
```

#### Pod stuck in `Pending`
Determine if cluster compute resources are exhausted.
```bash
# 1. Inspect Scheduler logs
kubectl describe pod [POD_NAME] -n production

# 2. Check cluster node limits and allocations
kubectl describe nodes \| grep -A 5 "Allocated resources"

# 3. Scale user node count if quota allows
az aks nodepool scale \
  --resource-group docbridge-rg \
  --cluster-name docbridge-dev-aks \
  --name user \
  --node-count 2
```

---

## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 7: END-TO-END REBOOT & DEPLOYMENT RUNBOOK
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If the entire cloud environment needs to be stood up from scratch, execute these phases in exact sequence:

### PHASE 1: BOOTSTRAP (Local Machine)
1. Install toolsets listed in **Section 1.1**.
2. Run login and authenticate subscription:
   ```bash
   az login
   az account set --subscription "f1808c66-ab07-46b3-bb93-06c6f2f406dc"
   ```
3. Run backend storage bootstrap commands to provision `docbridgestate849310` (**Section 2.1**).
4. Run App Registration OIDC commands to register `DocBridge-DevOps` SP (**Section 1.5**).
5. Add secrets in Git repositories using GitHub CLI (`gh secret set`, **Section 1.3**).
6. Configure `production` environment gates (**Section 1.4**).

### PHASE 2: INFRASTRUCTURE (Local / GitHub Actions)
7. Clone the Terraform repository:
   ```bash
   git clone https://github.com/Docbridge-devops-project/DocBridge-terraform.git
   cd DocBridge-terraform/terraform
   ```
8. Initialize and run apply locally (or push code to trigger the GitHub Actions workflow):
   ```bash
   terraform init -backend-config="resource_group_name=docbridge-rg" -backend-config="storage_account_name=docbridgestate849310" -backend-config="container_name=tfstate" -backend-config="key=dev.terraform.tfstate"
   terraform apply -var-file="secrets.tfvars" -auto-approve
   ```
9. Confirm execution completes successfully and outputs resource maps.

### PHASE 3: KUBERNETES BOOTSTRAP (Management VM)
10. Download the SSH private key:
    ```bash
    az keyvault secret download --vault-name docbridge-dev-kv --name mgmt-vm-ssh-private-key --file id_rsa --overwrite
    chmod 400 id_rsa
    ```
11. Tunnel to the management VM using Bastion:
    ```bash
    az network bastion ssh --name docbridge-dev-bastion --resource-group docbridge-rg --target-resource-id /subscriptions/f1808c66-ab07-46b3-bb93-06c6f2f406dc/resourceGroups/docbridge-rg/providers/Microsoft.Compute/virtualMachines/docbridge-dev-mgmt-vm --auth-type ssh-key --username adminuser --ssh-key id_rsa
    ```
12. Configure credentials and install Argo CD inside the private VM session:
    ```bash
    az aks get-credentials --resource-group docbridge-rg --name docbridge-dev-aks --overwrite-existing
    kubectl create namespace argocd
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm install argocd argo/argo-cd --namespace argocd --values ./docbridge-kubernetes/argocd/install/values.yaml
    ```
13. Apply GitOps manifests:
    ```bash
    kubectl apply -f ./docbridge-kubernetes/argocd/project.yaml
    kubectl apply -f ./docbridge-kubernetes/argocd/application.yaml
    ```

### PHASE 4: APPLICATION PROMOTION (GitHub Actions)
14. Commit changes to the `DocBridge-application` repository. Push code to trigger the `DocBridge Build Pipeline` workflow.
15. Verify that Docker images compile, Trivy security check runs, and images push to ACR `docbridgedevacr`.
16. The build pipeline will automatically trigger the `DocBridge Deploy Pipeline`.
17. Open the Actions run in the browser and click **Approve** on the `production` environment review gate.
18. The deploy job updates `argocd/application.yaml` inside `DocBridge-kubernetes`, which triggers Argo CD to sync.
19. Allow 90 seconds for rollout. The smoke test job runs and validates that public ingress `http://20.118.10.38/healthz` returns `200 OK`.

---

## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 8: FINAL CHEATSHEET
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌──────────────────────────────────────────────────────────────────────────┐
│                          PROJECT QUICK REFERENCE                         │
├──────────────────────────────────────────────────────────────────────────┤
│ AKS Cluster:      docbridge-dev-aks                                      │
│ Resource Group:   docbridge-rg                                           │
│ Container Registry:docbridgedevacr.azurecr.io                            │
│ App Namespaces:   production, argocd                                     │
│ State Storage:    docbridgestate849310                                   │
│ Managed Identity: docbridge-dev-workload-identity                        │
│ Workload Client ID:f20c8a93-cb30-4391-b59e-796a90c4f936                  │
│ PostgreSQL Server:docbridge-dev-postgres-c.postgres.database.azure.com   │
│ Key Vault Name:   docbridge-dev-kv                                       │
│ Public Ingress IP:20.118.10.38                                           │
│ Argo CD Password: DKmA6-r7wmlnRl0Z                                       │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                        PIPELINE TRIGGER COMMANDS                         │
├──────────────────────────────────────────────────────────────────────────┤
│ # Manual Terraform Apply Run                                             │
│ gh workflow run terraform-apply.yml \                                    │
│   --repo Docbridge-devops-project/DocBridge-terraform -f action=apply    │
│                                                                          │
│ # Manual Application Compilation & Scan Run                              │
│ gh workflow run build.yml \                                              │
│   --repo Docbridge-devops-project/DocBridge-application                  │
│                                                                          │
│ # Manual GitOps Deploy Run                                               │
│ gh workflow run deploy.yml \                                             │
│   --repo Docbridge-devops-project/DocBridge-application                  │
│                                                                          │
│ # Live Monitor Workflow Run                                              │
│ gh run watch --repo Docbridge-devops-project/DocBridge-application       │
│                                                                          │
│ # View Failures Logs                                                     │
│ gh run view [RUN_ID] --log-failed \                                      │
│   --repo Docbridge-devops-project/DocBridge-application                  │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                            TERRAFORM COMMANDS                            │
├──────────────────────────────────────────────────────────────────────────┤
│ Init:    terraform init -backend-config="resource_group_name=docbridge-rg│
│          " -backend-config="storage_account_name=docbridgestate849310" \ │
│          -backend-config="container_name=tfstate" \                      │
│          -backend-config="key=dev.terraform.tfstate"                     │
│ Validate:terraform validate                                              │
│ Format:  terraform fmt -recursive                                        │
│ Plan:    terraform plan -var-file="secrets.tfvars" -out=tfplan           │
│ Apply:   terraform apply tfplan                                          │
│ Target:  terraform apply -target=module.aks -var-file="secrets.tfvars"   │
│ State Ls:terraform state list                                            │
│ Unlock:  terraform force-unlock [LOCK_ID]                                │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                       KUBECTL ESSENTIAL COMMANDS                         │
├──────────────────────────────────────────────────────────────────────────┤
│ # BASTION SSH TUNNEL FOR PORT-FORWARDING (Run locally to expose ArgoCD)  │
│ az network bastion ssh --name docbridge-dev-bastion --resource-group \   │
│   docbridge-rg --target-resource-id /subscriptions/f1808c66-ab07-46b3- \ │
│   bb93-06c6f2f406dc/resourceGroups/docbridge-rg/providers/Microsoft. \   │
│   Compute/virtualMachines/docbridge-dev-mgmt-vm --auth-type ssh-key \    │
│   --username adminuser --ssh-key id_rsa -- -L 8080:127.0.0.1:8080        │
│                                                                          │
│ # RUNNING INSIDE MANAGEMENT VM SESSIONS:                                 │
│ # Fetch Credentials                                                      │
│ az aks get-credentials --resource-group docbridge-rg --name \            │
│   docbridge-dev-aks --overwrite-existing                                 │
│                                                                          │
│ # Port Forward ArgoCD Server (Run inside SSH VM session)                 │
│ kubectl port-forward svc/argocd-server -n argocd 8080:80                 │
│                                                                          │
│ # Pod status queries                                                     │
│ kubectl get pods -n production                                           │
│ kubectl get pods -n production -w                                        │
│ kubectl get svc -n production                                            │
│                                                                          │
│ # Debug logs & descriptions                                              │
│ kubectl describe pod [POD_NAME] -n production                            │
│ kubectl logs [POD_NAME] -n production --previous                         │
│ kubectl logs deployment/api-gateway -n production --tail=100             │
│                                                                          │
│ # Rollback Deployments                                                   │
│ kubectl rollout undo deployment/frontend -n production                   │
│ kubectl rollout status deployment/frontend -n production                 │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                         AZURE CLI QUICK COMMANDS                         │
├──────────────────────────────────────────────────────────────────────────┤
│ # Check AKS settings                                                     │
│ az aks show --name docbridge-dev-aks --resource-group docbridge-rg       │
│                                                                          │
│ # Scale system nodepools                                                 │
│ az aks nodepool scale --cluster-name docbridge-dev-aks --resource-group \│
│   docbridge-rg --name system --node-count 1                              │
│                                                                          │
│ # Registry repositories                                                  │
│ az acr repository list --name docbridgedevacr -o table                   │
│ az acr repository show-tags --name docbridgedevacr --repository frontend │
│                                                                          │
│ # Look up Key Vault Secrets                                              │
│ az keyvault secret list --vault-name docbridge-dev-kv                    │
│ az keyvault secret download --vault-name docbridge-dev-kv --name \       │
│   mgmt-vm-ssh-private-key --file id_rsa --overwrite                      │
│                                                                          │
│ # Verify Role assignments                                                │
│ az role assignment list --assignee "f20c8a93-cb30-4391-b59e- \          │
│   796a90c4f936" --output table                                           │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                        QUICK DEBUG DECISION TREE                         │
├──────────────────────────────────────────────────────────────────────────┤
│ Ingress returning 502 Bad Gateway?                                       │
│  → Run az network application-gateway show-backend-health                │
│  → If empty target: restart AGIC controller pod in kube-system namespace │
│                                                                          │
│ Pod stuck in ImagePullBackOff?                                           │
│  → Describe pod, look at events. Verify AKS has AcrPull role bound.      │
│  → Check image tag exists in ACR registry repository.                    │
│                                                                          │
│ Pod stuck in CrashLoopBackOff?                                           │
│  → Run kubectl logs --previous to view failed application logs.          │
│  → Verify ConfigMap settings and Database password secrets.              │
│                                                                          │
│ Terraform Apply deletes dynamic App Gateway pools?                       │
│  → Ensure lifecycle rules are enabled in azurerm_application_gateway.    │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    PRE-PRESENTATION VERIFY CHECKLIST                     │
├──────────────────────────────────────────────────────────────────────────┤
│ □ kubectl get nodes → all systems Ready                                  │
│ □ kubectl get pods -n production → 23 compute pods Running               │
│ □ kubectl get ingress -n production → EXTERNAL-IP assigned               │
│ □ curl http://20.118.10.38/healthz → HTTP 200 OK                         │
│ □ curl http://20.118.10.38/ready → HTTP 200 OK                           │
│ □ GitHub Actions → all 3 build, deploy & infrastructure pipelines green  │
│ □ ArgoCD → Dashboard healthy & all microservices in-sync                 │
│ □ Log analytics queries → pod metrics logs populated without exceptions  │
└──────────────────────────────────────────────────────────────────────────┘
