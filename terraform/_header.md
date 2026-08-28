# Customized AI Landing Zone

This Terraform root is the compatibility entry point for the customized AI landing zone. It currently deploys the existing Portal ARM template through AzAPI while the landing-zone resources are migrated to discrete, typed Terraform resources.

The Portal/ARM path is a temporary legacy mode. New implementation work is AzAPI-first and preserves the existing input names so env0 integrations can migrate without an immediate contract break.

## Deployment sequencing

The authoritative Terraform implementation will enforce this dependency graph:

1. scopes and resource groups;
2. user-assigned managed identities;
3. hub, spoke, security appliance, Foundry, and application resources;
4. user-assigned identity attachment;
5. RBAC and data-plane role assignments; and
6. governance policy assignments.

No system-assigned managed identity is permitted in the authoritative implementation.
