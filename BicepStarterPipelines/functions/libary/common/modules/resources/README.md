# Resource Modules in Bicep

This folder is for local modules, including:
- Custom resource modules
- Wrapper modules for Azure Verified Modules

If you want to share modules across projects, consider using a Bicep module registry.

## What are Resource Modules?

Resource modules in Bicep are reusable building blocks that encapsulate the deployment of one or more Azure resources. They help organize infrastructure as code, promote reuse, and simplify complex deployments by allowing you to define, parameterize, and consume modules across different environments or projects.

## Typical Use Cases

- Encapsulating a single resource (e.g., a storage account) for reuse
- Grouping related resources (e.g., a storage account and storage containers)
- Enforcing standards and best practices across deployments
