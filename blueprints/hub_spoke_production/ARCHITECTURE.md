# Architecture and safety boundary

## Status

This folder is an isolated implementation blueprint. It is not referenced by the current root Terraform configuration, env0 template, Portal deployment, or documentation deployment workflows.

All Azure resources are disabled unless four independent controls are true:

- `deployment_enabled`;
- `blueprint_approved`;
- `marketplace_values_verified`; and
- `byol_terms_accepted`; and
- `move_subscriptions_to_management_group`.

Variable validation additionally rejects default subscription IDs, placeholder Foundry names, placeholder policy IDs, placeholder Marketplace values, unverified prefixes, `latest` image versions, and invalid SSH keys.

An enabled run also compares the active AzAPI principal object ID with the source-pinned `pinned_env0_deployment_principal_id` local. The placeholder cannot be overridden through tfvars. Azure RBAC must grant write permissions only to that env0 federated identity; plan-only human identities should not have deployment rights.

Management groups and resource groups use static `prevent_destroy`. Turning deployment or approval flags off after an apply therefore produces a blocked plan instead of deleting the landing zone. Teardown requires a separate reviewed source change and dedicated destroy workflow.

## Intended production flow

```text
existing or created management group
  -> three subscription resource groups
  -> all user-assigned managed identities
  -> hub and workload-spoke networks
  -> Palo Alto VM-Series BYOL active/passive pair
  -> Aviatrix Controller and HA transit gateway nodes
  -> peering and forced default route through Palo Alto
  -> Foundry, central private endpoint/DNS, Log Analytics, Sentinel
  -> user-assigned identity attachment
  -> least-privilege RBAC
  -> non-enforcing policy placeholders
```

Policy placeholders use `DoNotEnforce`. They must remain non-enforcing until parameters, exemptions, remediation identities, and impact have been reviewed against a real plan.

## Known placeholder boundaries

- Marketplace VM image coordinates are candidates only.
- VM sizes, availability zones, NIC count, boot diagnostics, load balancers, health probes, Panorama integration, Aviatrix bootstrap, and license activation require vendor design validation.
- The Palo Alto trusted address is a topology placeholder, not a validated HA next hop.
- The Reader role assignment demonstrates Stage 04 ordering; production role mappings must be reduced to exact permissions.
- Sentinel onboarding is present, but connectors, analytics rules, automation, workbooks, and appliance log parsing require separate resources.
- Foundry private DNS group and zone coverage must be verified against the final Foundry services.
- Entra groups remain owned by a separate identity-bootstrap stack or are supplied as existing object IDs.

## Apply authority

Harness validates and requests deployment. env0 is the only apply authority. Neither checked-in Harness pipeline contains a Terraform apply command.
