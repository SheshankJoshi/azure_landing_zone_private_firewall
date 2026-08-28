# Isolated blueprints

Blueprints in this folder are not referenced by the current Terraform root, Portal deployment, env0 template, or Harness pipeline.

## Hub-and-spoke production

The `hub_spoke_production/` blueprint packages the requested staged design:

- three subscription scopes;
- create-or-consume management group;
- user-assigned managed identities only;
- hub and Foundry workload spoke;
- Palo Alto VM-Series BYOL active/passive candidates;
- Aviatrix Controller and HA transit gateway candidates;
- internal and external Palo Alto load balancer placeholders;
- forced workload routing through the trusted Palo Alto frontend;
- central private endpoint and private DNS placeholders;
- Log Analytics and Sentinel onboarding;
- identity attachment, RBAC, and policy stages;
- env0-only apply authority; and
- separate Harness infrastructure and application pipelines.

Read `hub_spoke_production/ARCHITECTURE.md` before using the blueprint. Defaults do not create Azure resources.
