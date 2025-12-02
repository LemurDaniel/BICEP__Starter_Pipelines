# BICEP Starter Pipelines

Welcome to **BICEP Starter Pipelines**! 😺

Quickly set up a **Bicep project with pipelines**.

> ⚠️ Note: Looks may differ depending on your terminal.

![Example](./.assets/init.deployment.png)

<br>

## ⚠️ Prototype Notice

> This repository is currently a **prototype** and not fully tested.
>
> Includes [Bicep tests](https://github.com/Azure/bicep/issues/11967) (still in development).
> 
>Please be gentle 😅🦖 — improvements will come in future updates.

Tested mostly on **Windows**, may work differently on **Linux** and **macOS**:

* ✅ Windows
* ⚠️ Linux
* ⚠️ macOS

<br>

## ⚡ Version Control & Pipelines

**Supported Version Control Systems:**

* **GitHub**
* **Azure DevOps**

<br>

**Choose between either:**

**🚀 Deployment Pipelines** – Deploy a standard Bicep project at:

* Resource group scope
* Subscription scope

**📦 Registry Template** – Setup a custom private Bicep module registry.


<br>

## 🚀 Usage

### Method 1: Install from [PowerShell Gallery](https://www.powershellgallery.com/packages/BicepStarterPipelines)

```powershell
PS> Install-Module -Name BicepStarterPipelines -Scope CurrentUser
PS> bicep-init
```

### Method 2: Try Without Installation

**PowerShell Script**

```powershell
PS> ./bicep-init ./destinationFolder
```

> You can adjust the **destination folder**; by default, it initializes in the current directory.

<br>
Here’s a **reworked, concise, clear version** of your prerequisites section including the GitHub secret setup and Azure DevOps notes, keeping the registry block collapsible and well-structured 😺🚀

---
Here’s a **refined version** of your prerequisites section with clearer structure, consistent formatting, and concise wording, while keeping the collapsible details for Azure DevOps and GitHub. 😺🚀

---

## 🔧 Prerequisites

### Azure Authentication

**Requirement:** The Pipeline must be able to start deployments in Azure.

<details>
<summary><b>Azure DevOps</b></summary>

* Create the **Service Connection** and reference it directly in the `Deploy Bicep` pipeline.
* Service Connections must be available **before runtime**; using runtime variables may not work.

</details>

---

<details>
<summary><b>GitHub</b></summary>

Create a **repository- or environment-scoped secret** called `AZURE_AUTH`. Use one of the following formats:

#### Auth type: OIDC (Workload Identity Federation)

```json
AZURE_AUTH = {
  "auth_type": "OIDC",
  "tenantId": "00000000-0000-0000-0000-000000000000",
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "clientId": "00000000-0000-0000-0000-000000000000"
}
```

* Use a **Federated Credential** on either:

  * **User Managed Identity**: [Link](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust-user-assigned-managed-identity?pivots=identity-wif-mi-methods-azp#configure-a-federated-identity-credential-on-a-user-assigned-managed-identity)
  * **App Registration**: [Link](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions)

#### Auth type: ClientSecret

```json
AZURE_AUTH = {
  "auth_type": "ClientSecret",
  "tenantId": "00000000-0000-0000-0000-000000000000",
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "clientId": "00000000-0000-0000-0000-000000000000",
  "objectId": "00000000-0000-0000-0000-000000000000",
  "clientSecret": "00000000-0000-0000-0000-000000000000"
}
```

</details>

---

### Bicep Registry (Only required when using Bicep Regsitry Pipelines)

**Requirement:** The registry must be able to create/update **Git tags**.

<details>
<summary><b>Azure DevOps</b></summary>

* The build service must have **Contribute** permission on the repository:

  1. **Project Settings → Repos → Repositories → [Your Repo] → Security**
  2. Allow **Contribute** for one of:

     * `<Repository Name> Build Service`
     * `Project Collection Build Service <project>`
     * `Project Collection Build Services Account`

* More info: [Azure DevOps repo permissions](https://learn.microsoft.com/en-us/azure/devops/repos/git/set-git-repository-permissions?view=azure-devops#open-security-for-a-repository)

</details>

---

<details>
<summary><b>GitHub</b></summary>

(TODO)
* Ensure the workflow can push tags.

</details>

---

<br>

## 📦 Notes on the Registry

* Manages multiple modules, each in its own folder with a `version.json` containing:

  * `version`
  * `description`
  * `deployment_tests`

* Automatically detects which modules to update:

  * **Pull Request** – all changes between branches
  * **Push** – checks `meta_last_publish_<branch>` marker after successful publish