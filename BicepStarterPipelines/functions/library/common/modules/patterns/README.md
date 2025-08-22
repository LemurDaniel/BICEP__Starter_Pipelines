# Bicep Patterns Modules

This folder contains **local modules** for Bicep patterns, including:
- **Custom pattern modules**
- **Wrapper modules for [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/indexes/bicep)**

If you want to share patterns across projects, consider using a Bicep module registry.

## What are Patterns Modules?

Patterns modules help you implement common architectural patterns or best practices by combining resources and modules into standardized, repeatable templates.

### Typical Use Cases

- Deploying compositions of multiple resources and resource modules
    - For Example: 
    - App Gateway, Key Vault, Networking, and related resources
    - Container Registry with networking and identity
- Enforcing organizational standards across environments