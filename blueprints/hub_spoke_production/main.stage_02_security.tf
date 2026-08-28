resource "azapi_resource" "application_security_group" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.application_security_groups
  name      = "asg-ai-application-placeholder"
  parent_id = azapi_resource.resource_group["workload"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {}
  }

  ignore_body_changes    = length(var.ignore_body_changes.application_security_groups) > 0 ? var.ignore_body_changes.application_security_groups : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [terraform_data.stage_01_identities_complete]
}

resource "azapi_resource" "workload_network_security_group" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.network_security_groups
  name      = "nsg-ai-workload-placeholder"
  parent_id = azapi_resource.resource_group["workload"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      securityRules = [
        {
          name = "deny-direct-internet-inbound"
          properties = {
            access                   = "Deny"
            destinationAddressPrefix = "*"
            destinationPortRange     = "*"
            direction                = "Inbound"
            priority                 = 4096
            protocol                 = "*"
            sourceAddressPrefix      = "Internet"
            sourcePortRange          = "*"
          }
        }
      ]
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.network_security_groups) > 0 ? var.ignore_body_changes.network_security_groups : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [terraform_data.stage_01_identities_complete]
}
