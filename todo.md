| ✅ | Task | Description |
|----|------|-------------|
| ✅ | Test IP-Rules auf neuer Registry | Temporäre IP-Rules korrekt setzen und wieder entfernen. Sicherstellen, dass Deploys auch bei restriktiven Netzen funktionieren. |
| ✅ | Marker-Logik portieren | Marker für letzte erfolgreiche Deploys aus DevOps übernehmen. Prüfen, dass Marker nur bei echten Deploys gesetzt werden. |
| ✅ | Exclusions: Add Test exclusions for sepcific modules | Maybe disable it in the version.json and handle logic in detect changes script |
| ⬜ | Test: Github Registry Deployment Pipeline testen | Deploy Scripts auf GitHub Actions laufen lassen. Prüfen, dass Module korrekt deployed werden, inklusive Zugriff auf Registry. |
| ⬜ | Test: Github Update Marker | Letzte erfolgreiche Deploys auch in GitHub markieren. Logik testen, dass nur geänderte Module bei zukünftigen Runs erkannt werden. |
| ⬜ | Test: Github Final Check / Init | Init über PowerShell Starter Pipeline Repo. Alle funktionierenden Changes aus dem Modul drin. Sicherstellen, dass alles direkt wiederverwendbar ist. |
| ⬜ | README: Deployment Template – Azure DevOps | Overview, Prerequisites (Azure Subscription, DevOps Project, Bicep CLI), Usage (Pipeline Trigger, Parameters), Marker Logic, Testing/Debug, References/Links |
| ⬜ | README: Deployment Template – GitHub Actions | Overview, Prerequisites (GitHub Repo access, Actions enabled), Usage (Workflow triggers, Secrets, Parameters), Marker Logic, IP-Rules, Testing, References |
| ⬜ | README: Registry Template – Azure DevOps | Overview (what the registry template does), Prerequisites (Azure Subscription, DevOps Project), Usage (how to publish modules, parameters), Marker Logic, Versioning, Testing, References |
| ⬜ | README: Registry Template – GitHub Actions | Overview, Prerequisites (GitHub Repo, Actions), Usage (publish modules workflow, parameters, secrets), Marker Logic, Versioning, Testing, References |
| ⬜ | Test: Github Deployment init + testen | Normale Deployment pipelines init auf Github und testen (neues demo deployment testen) |
| ⬜ | Test: Azure DevOps init + testen | Normale Deployment pipelines init auf Azure DevOps und testen (neues demo deployment testen) |