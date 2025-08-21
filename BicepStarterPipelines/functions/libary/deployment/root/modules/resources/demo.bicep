/*
  Bicep Resource Modules Explanation:

  This folder is for local modules:
  - custom resource modules
  - wrapper modules for Azure Verified Modules

  If you want to share modules across projects, consider using a bicep module registry.

  Resource modules in Bicep are reusable building blocks that encapsulate the deployment of one or more Azure resources.
  They help organize infrastructure as code, promote reuse, and simplify complex deployments by allowing you to define,
  parameterize, and consume modules across different environments or projects.

  Typical use cases:
    - Encapsulating a single resource (e.g., a storage account) for reuse
    - Grouping related resources (e.g., a web app and its database)
    - Enforcing standards and best practices across deployments

  Modules are referenced using the 'module' keyword and can accept parameters and return outputs.
*/
