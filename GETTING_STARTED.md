# Getting Started

## Prerequisites

- PowerShell 7.2+
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

---

## 1. Install the Module

**From PowerShell Gallery (recommended):**

```powershell
Install-Module -Name BicepStarterPipelines -Scope CurrentUser
```

**Or clone and import locally:**

```powershell
git clone https://github.com/LemurDaniel/LemurDaniel-BICEP--Starter-Pipelines
Import-Module ./BicepStarterPipelines/
```

---

## 2. Run the Wizard

```powershell
bicep-init  -Target ./my-project
```

Aliases are also available for direct template selection:

```powershell
bicep-deployment -Target ./my-project   # skips template selection, picks Deployment
bicep-registry   -Target ./my-project   # skips template selection, picks Registry
```

The wizard will interactively prompt for:

| Prompt | Options |
|---|---|
| Template | `Bicep Deployment` / `Bicep Registry` |
| Deployment Method | `Normal Deployment` / `Deployment Stack` |
| Scope | `Resource Group` / `Subscription` |
| Pipeline | `Azure DevOps` / `Github` |

---

## 3. Setup

<details>
<summary><strong>GitHub Actions</strong></summary>

### ✅ Checklist

- [ ] `AZURE_AUTH` secret created (repository or per environment)
- [ ] Federated credential configured (OIDC) **or** App Registration client secret set
- [ ] Pipeline identity has the required RBAC role on the target subscription / resource group

- [ ] *(Registry only)* Workflow permissions set to **Read and write** (to push Git tags)
- [ ] *(Registry only)* Pipeline identity has **AcrPush** role on the registry
- [ ] *(Registry only)* Param files adjusted and pushed to trigger `deploy.infra.prod.yaml`
- [ ] *(Registry only)* `REGISTRY_NAME` and `DEFAULT_LOCATION` variables set

---

### 🔐 Authentication

The generated workflows authenticate via a single repository or per-environment secret named **`AZURE_AUTH`**.

Go to **Settings → Secrets and variables → Actions** in your repository and create the secret.

#### Option A — OIDC / Workload Identity Federation (recommended, no secret rotation)

```json
{
  "auth_type": "OIDC",
  "tenantId":       "00000000-0000-0000-0000-000000000000",
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "clientId":       "00000000-0000-0000-0000-000000000000"
}
```

Create the federated credential on either:
- [User Assigned Managed Identity](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust-user-assigned-managed-identity?pivots=identity-wif-mi-methods-azp#configure-a-federated-identity-credential-on-a-user-assigned-managed-identity)
- [App Registration](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions)

Set the federated credential subject to match your repository and branch/environment, e.g.:
```
repo:<org>/<repo>:environment:prod
repo:<org>/<repo>:ref:refs/heads/main
```

#### Option B — Client Secret

```json
{
  "auth_type":      "ClientSecret",
  "tenantId":       "00000000-0000-0000-0000-000000000000",
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "clientId":       "00000000-0000-0000-0000-000000000000",
  "clientSecret":   "00000000-0000-0000-0000-000000000000"
}
```

The secret can be scoped per environment (recommended) or at repository level as a fallback.

---

### 📦 Registry — Additional Setup

> Only needed when you selected the **`Bicep Registry`** template.

#### 🏗️ Deploy the Registry Infrastructure

The scaffold includes a ready-to-use Bicep template under `infra/` and the pipelines `deploy.infra.prod.yaml` / `deploy.infra.test.yaml` that deploy it.

Adjust the param files (`infra/params/registry.prod.bicepparam`, `infra/params/registry.test.bicepparam`) to set your registry name, location, and network settings.

Also update the pipeline files to match your environment — replace the resource group, deployment name, and parameter file as needed:

```yaml
with:
  environment: prod           # ← GitHub environment (optional, for scoped secrets/vars)

  scope: resource_group
  resource_group: 'rg-sample-prod'        # ← your resource group

  deployment_name: 'sample-registry-prod' # ← deployment name
  template_file: ./infra/registry.scope.resource_group.bicep
  parameter_file: ./infra/params/registry.prod.bicepparam

  what_if_only: ${{ github.EVENT_NAME == 'pull_request' || inputs.what_if_only == true }}

  # set_temporary_ip_rules: |   # ← uncomment if your ACR has network restrictions
  #   acrsampleprod
```

The pipelines trigger on push/PR when files under `infra/` change. On Pull Requests they run a what-if only; the actual deployment happens on merge.

#### ⚙️ Configure Pipeline Variables

In **Settings → Secrets and variables → Actions → Variables** add:

| Variable | Example value |
|---|---|
| `REGISTRY_NAME` | `acrsampleprod` |
| `DEFAULT_LOCATION` | `westeurope` |

These can also be set per GitHub Environment if you use separate registries per stage.

#### 🔑 Grant AcrPush Permission

The pipeline identity (App Registration or Managed Identity) needs the **AcrPush** role on the registry.

#### 🏷️ Allow Workflow to Push Git Tags

The publish pipeline sets a Git tag (`meta-last-publish-marker-<branch>`) after each successful run to track which modules were last published. GitHub Actions needs write access to do this.

Go to **Settings → Actions → General → Workflow permissions** and enable **Read and write permissions**.

#### 🚀 Publishing Modules

Once set up, the publish pipeline (`publish.bicep.modules.prod.yaml`) runs automatically on:
- **Pull Request** against `master` / `main` — test-deploys changed modules (verify only, does not publish).
- **Push / Merge** to `master` / `main` — detects changed modules via git diff since the last publish marker tag and publishes them to the ACR.

Modules are discovered under the `modules/` folder. Each module must have a `version.json` to be picked up by the change detection logic.

</details>

<details>
<summary><strong>Azure DevOps</strong></summary>

### ✅ Checklist

- [ ] Service Connection(s) created in Project Settings (one per environment)
- [ ] `serviceConnection` placeholder replaced in `.devops/deploy.bicep.infra.yaml`
- [ ] Environments created in **Pipelines → Environments** (with optional approval gates)
- [ ] *(Registry only)* Build Service has **Contribute** permission on the repository (for Git tags)
- [ ] *(Registry only)* Service Connection identity has **AcrPush** role on the registry
- [ ] *(Registry only)* Param files adjusted and pushed to trigger `deploy.bicep.infra.yaml`
- [ ] *(Registry only)* `registryName` updated per stage in `.devops/publish.bicep.modules.yaml`

---

### 🔐 Authentication

The generated pipelines use **Service Connections** — one per environment (Dev / Test / Prod).

1. Go to **Project Settings → Service connections → New service connection → Azure Resource Manager**.
2. Create a connection for each environment with the appropriate scope (Resource Group or Subscription).
3. Open the generated pipeline file (`.devops/deploy.bicep.infra.yaml`) and replace the placeholder names:

```yaml
serviceConnection: project-connection-dev   # ← replace with your actual connection name
serviceConnection: project-connection-test
serviceConnection: project-connection-prod
```

4. Create the corresponding **Environments** in **Pipelines → Environments** and optionally configure approval gates on them.

---

### 📦 Registry — Additional Setup

> Only needed when you selected the **`Bicep Registry`** template.

#### 🏗️ Deploy the Registry Infrastructure

The scaffold includes a ready-to-use Bicep template under `infra/` and the pipeline `deploy.bicep.infra.yaml` that deploys it.

Adjust the param files (`infra/params/registry.prod.bicepparam`, `infra/params/registry.test.bicepparam`) to set your registry name, location, and network settings, then push to trigger the pipeline.

`deploy.bicep.infra.yaml` triggers on the `dev` and `master` branches when files under `infra/` change.

#### ⚙️ Configure Pipeline Variables

In the generated `.devops/publish.bicep.modules.yaml`, update the `registryName` parameter per stage:

```yaml
registryName: acrsampleprod   # ← your actual ACR name
```

You can also add a variable group (e.g., `bicep-registry-vars`) and reference it from the pipeline.

#### 🔑 Grant AcrPush Permission

The Service Connection's identity needs the **AcrPush** role on the registry.

#### 🏷️ Grant Build Service Repo Permissions

The publish pipeline sets a Git tag (`meta-last-publish-marker-<branch>`) after each successful run to track which modules were last published. The Azure DevOps build service needs **Contribute** on the repository to push tags.

1. Go to **Project Settings → Repos → Repositories → [Your Repo] → Security**
2. Find one of the following identities and set **Contribute** to **Allow**:
   - `<Repository Name> Build Service`
   - `Project Collection Build Service <project>`

More info: [Azure DevOps repository permissions](https://learn.microsoft.com/en-us/azure/devops/repos/git/set-git-repository-permissions?view=azure-devops#open-security-for-a-repository)

#### 🚀 Publishing Modules

Once set up, the publish pipeline (`publish.bicep.modules.yaml`) runs automatically on:
- **Pull Request** — test-deploys changed modules (verify only, does not publish).
- **Push / Merge** to `dev` or `master` — detects changed modules via git diff since the last publish marker tag and publishes them to the ACR.

Modules are discovered under the `modules/` folder. Each module must have a `version.json` to be picked up by the change detection logic.

</details>
