mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      object_id       = "00000000-0000-0000-0000-000000000004"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
}

run "disabled_by_default" {
  command = apply

  assert {
    condition     = output.deployment_enabled == false
    error_message = "The isolated blueprint must not deploy Azure resources by default."
  }

  assert {
    condition     = output.deployment_sequence == null
    error_message = "No deployment stages may execute while the blueprint is disabled."
  }
}

run "rejects_unapproved_deployment" {
  command = plan

  variables {
    deployment_enabled = true
  }

  expect_failures = [
    check.deployment_gate,
    terraform_data.deployment_authorization,
    var.appliance_admin_ssh_public_key,
    var.foundry_name,
    var.management_group,
    var.marketplace_images,
    var.policy_definition_ids,
    var.subscriptions,
  ]
}

run "rejects_non_env0_principal" {
  command = plan

  variables {
    deployment_enabled                     = true
    blueprint_approved                     = true
    marketplace_values_verified            = true
    byol_terms_accepted                    = true
    move_subscriptions_to_management_group = true
    appliance_admin_ssh_public_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQBlueprintOnly"
    foundry_name                           = "foundry-blueprint-unit-test"

    subscriptions = {
      connectivity        = "00000000-0000-0000-0000-000000000010"
      identity_management = "00000000-0000-0000-0000-000000000011"
      workload            = "00000000-0000-0000-0000-000000000012"
    }

    management_group = {
      mode         = "create"
      name         = "mg-blueprint-unit-test"
      display_name = "Blueprint Unit Test"
    }

    marketplace_images = {
      palo_alto = {
        publisher = "verified-publisher"
        offer     = "verified-offer"
        plan      = "verified-plan"
        sku       = "verified-sku"
        version   = "1.0.0"
      }
      aviatrix = {
        publisher = "verified-publisher"
        offer     = "verified-offer"
        plan      = "verified-plan"
        sku       = "verified-sku"
        version   = "1.0.0"
      }
    }

    policy_definition_ids = {
      deny_public_network_access = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000020"
      require_diagnostics        = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000021"
      require_user_assigned_id   = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000022"
    }
  }

  expect_failures = [terraform_data.deployment_authorization]
}
