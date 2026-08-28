# Hub-and-Spoke Production Blueprint

This is an isolated, non-authoritative AzAPI-first blueprint for the requested production topology. It does not change the current `terraform/` entry point or env0 working directory.

The blueprint is disabled by default and contains conspicuous placeholder Marketplace coordinates. Azure resources are created only when all deployment gates are explicitly enabled after architecture, licensing, security, routing, and cost review.

## Sequence

1. scopes;
2. user-assigned managed identities;
3. hub, spoke, Palo Alto, Aviatrix, Foundry, private connectivity, and monitoring resources;
4. user-assigned identity attachment;
5. RBAC;
6. policy assignments.

File names document this sequence. Terraform references and completion barriers enforce it.
