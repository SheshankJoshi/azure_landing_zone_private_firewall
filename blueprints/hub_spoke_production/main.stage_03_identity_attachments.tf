resource "azapi_update_resource" "appliance_identity" {
  for_each = local.enabled_appliance_nodes

  type        = var.resource_types.virtual_machines
  resource_id = azapi_resource.appliance_virtual_machine[each.key].id

  body = {
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        (azapi_resource.managed_identity[each.value.identity_key].id) = {}
      }
    }
  }

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

  depends_on = [terraform_data.stage_02_resources_complete]
}

resource "azapi_update_resource" "foundry_identity" {
  count = local.enabled ? 1 : 0

  type        = var.resource_types.identity_attachments
  resource_id = azapi_resource.foundry[0].id

  body = {
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        (azapi_resource.managed_identity["foundry"].id) = {}
      }
    }
  }

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

  depends_on = [terraform_data.stage_02_resources_complete]
}

resource "terraform_data" "stage_03_identity_attachments_complete" {
  count = local.enabled ? 1 : 0

  input = {
    appliance_identity_attachments = keys(azapi_update_resource.appliance_identity)
    foundry_identity_attachment    = azapi_update_resource.foundry_identity[0].id
  }

  depends_on = [
    azapi_update_resource.appliance_identity,
    azapi_update_resource.foundry_identity,
  ]
}
