mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock"
      name = "mock"
      output = {
        properties = {
          clientId    = "00000000-0000-0000-0000-000000000002"
          principalId = "00000000-0000-0000-0000-000000000003"
          tenantId    = "00000000-0000-0000-0000-000000000001"
        }
      }
    }
  }
}

variables {
  portal_parameters = {
    vmPassword = "unit-test-only"
  }
}

run "legacy_compatibility_defaults" {
  command = apply

  assert {
    condition     = azapi_resource.resource_group.type == "Microsoft.Resources/resourceGroups@2024-03-01"
    error_message = "The compatibility resource group must use the tested AzAPI resource type."
  }

  assert {
    condition     = azapi_resource.legacy_arm_deployment.body.properties.mode == "Incremental"
    error_message = "The legacy compatibility deployment must preserve incremental ARM deployment behavior."
  }

  assert {
    condition     = length(output.managed_identities) == 0
    error_message = "Managed identities must remain opt-in for existing compatibility callers."
  }
}

run "creates_user_assigned_identities_before_resources" {
  command = apply

  variables {
    managed_identities = {
      foundry = {
        name = "id-foundry-test"
      }
    }
  }

  assert {
    condition     = azapi_resource.managed_identity["foundry"].type == "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
    error_message = "Stage 01 must create a user-assigned managed identity resource."
  }

  assert {
    condition     = terraform_data.stage_01_identities_complete.input.managed_identity_ids.foundry == azapi_resource.managed_identity["foundry"].id
    error_message = "The identity-stage barrier must include every enabled managed identity."
  }

  assert {
    condition     = output.deployment_sequence.stage_01_identities != null
    error_message = "The deployment sequence must expose completion of the identity stage."
  }
}
