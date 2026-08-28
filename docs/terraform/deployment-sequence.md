# Terraform deployment sequence

## Source-of-truth boundary

This repository is the customized implementation. The public `terraform-azurerm-avm-ptn-aiml-landing-zone` repository is a design reference only and is not deployed by this repository.

The Terraform root under `terraform/` is becoming the authoritative deployment path. The Portal ARM template remains a temporary compatibility deployment while its resources are migrated and imported into discrete Terraform addresses.

## Enforced graph

Terraform evaluates dependencies, not file names. Topic file names make the lifecycle visible to reviewers, while completion barriers and resource references enforce it:

```text
Stage 00: scopes and resource groups
  |
  v
Stage 01: user-assigned managed identities
  |
  v
Stage 02: networks, appliances, platform, Foundry, and application resources
  |
  v
Stage 03: user-assigned identity attachment
  |
  v
Stage 04: Azure RBAC and service data-plane roles
  |
  v
Stage 05: management-group and subscription policy assignments
```

The compatibility implementation currently enforces Stage 00, Stage 01, and the legacy ARM deployment boundary. Later stages will replace the ARM deployment incrementally.

## Stage 00: scopes

This stage creates or consumes management groups, selects the connectivity, identity/management, and workload subscriptions, and creates the required resource groups.

The management-group contract will support two modes:

- `create` creates the configured hierarchy.
- `existing` consumes supplied management-group resource IDs and creates no hierarchy.

## Stage 01: identities

All workload identities are user-assigned managed identities created before workload resources. The authoritative implementation must never emit `SystemAssigned` or `SystemAssigned, UserAssigned`.

The `managed_identities` map uses caller-chosen stable keys so identities can be referenced consistently by resources, role assignments, env0 variables, and migration tooling.

Entra user and identity groups belong to a separate identity-bootstrap stack. This landing-zone stack consumes that stack's outputs or pre-existing group object IDs.

## Stage 02: resources

The production topology will contain:

- a connectivity hub in its own subscription;
- a Palo Alto VM-Series BYOL active/passive pair;
- an Aviatrix Controller and HA transit gateways;
- forced transit inspection through Palo Alto;
- central private endpoints and private DNS in the hub; and
- Foundry and application services in a workload spoke.

Internal Stage 02 references will order network foundations before appliances, appliances before routing, and shared connectivity before workload private endpoints.

## Stage 03: identity attachment

Where Azure supports post-creation identity updates, a dedicated AzAPI update resource will attach the Stage 01 UAMI after the workload resource exists.

If an Azure resource requires a UAMI in its create payload, it still depends on the Stage 01 completion barrier. The resource-specific limitation must be documented and tested rather than hidden.

## Stage 04: RBAC

Role assignments begin only after identity attachment completes. This includes Azure RBAC and service-specific data-plane roles for Key Vault, Storage, ACR, Cosmos DB, Foundry, monitoring, and appliance automation.

Assignments use deterministic names and stable map keys. Retry configuration handles bounded propagation delays; pipelines do not use arbitrary sleep commands.

## Stage 05: policy

Policy assignments begin only after RBAC completes. This prevents policy enforcement from blocking the identity and access configuration needed to finish the deployment.

Policy coverage includes public-network denial, required private connectivity, diagnostics, allowed locations and SKUs, tagging, Defender/Sentinel controls, and UAMI-only requirements where Azure Policy aliases support enforcement.

## env0 and Harness ownership

env0 is the only infrastructure apply authority. Harness performs formatting, validation, unit and policy tests, publishes plan evidence, obtains approval, and requests or promotes the env0 deployment.

Application delivery is a separate Harness pipeline that builds, scans, signs, pushes to ACR, and promotes an Azure Container Apps revision. It does not own infrastructure state.

## Migration safety

Resources created inside the legacy ARM deployment do not have individual Terraform state addresses. Migration therefore requires:

1. an Azure resource inventory;
2. a state backup;
3. setting `migrate_legacy_azurerm_state = true` for the one-time wrapper-provider migration;
4. a plan showing the old AzureRM wrapper addresses removed without destroy and the same Azure IDs imported into AzAPI addresses;
5. an apply followed by resetting `migrate_legacy_azurerm_state = false`;
6. a second no-change plan;
7. discrete imports for resources currently hidden inside the ARM deployment; and
8. removal of each migrated resource from legacy ARM ownership.

`moved` blocks cannot move resources that were never represented individually in Terraform state.
