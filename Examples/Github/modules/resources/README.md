# Resource Modules in Bicep

This folder contains **local modules** for Bicep patterns, including:
- **Custom pattern modules**
- **Wrapper modules for [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/indexes/bicep)**

If you want to share patterns across projects, consider using a Bicep module registry.

## What are Resources Modules?

Resource modules in Bicep are reusable building blocks that encapsulate the deployment of one or more Azure resources. They help organize infrastructure as code, promote reuse, and simplify complex deployments by allowing you to define, parameterize, and consume modules across different environments or projects.

## Typical Use Cases

- Encapsulating a single resource (e.g., a storage account) for reuse
- Grouping related resources (e.g., a storage account and storage containers)
- Enforcing standards and best practices across deployments
