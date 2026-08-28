locals {
  identity_role_scopes = {
    palo_alto_automation = "connectivity"
    aviatrix             = "connectivity"
    foundry              = "workload"
    application          = "workload"
    monitoring           = "identity_management"
    deployment           = "identity_management"
  }

  enabled_identity_role_scopes = local.enabled ? local.identity_role_scopes : {}
}

resource "azapi_resource" "identity_reader_role_assignment" {
  for_each = local.enabled_identity_role_scopes

  type      = var.resource_types.role_assignments
  name      = uuidv5("url", "${azapi_resource.resource_group[each.value].id}|${each.key}|Reader")
  parent_id = azapi_resource.resource_group[each.value].id

  body = {
    properties = {
      principalId      = azapi_resource.managed_identity[each.key].output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${local.resource_groups[each.value].subscription_id}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.role_assignments) > 0 ? var.ignore_body_changes.role_assignments : null
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

  depends_on = [terraform_data.stage_03_identity_attachments_complete]
}

resource "terraform_data" "stage_04_rbac_complete" {
  count = local.enabled ? 1 : 0

  input = {
    role_assignment_ids = {
      for key, assignment in azapi_resource.identity_reader_role_assignment : key => assignment.id
    }
  }

  depends_on = [azapi_resource.identity_reader_role_assignment]
}
