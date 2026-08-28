resource "azapi_resource" "managed_identity" {
  for_each = var.managed_identities

  type      = var.resource_types.managedidentity_user_assigned_identities
  name      = each.value.name
  parent_id = coalesce(each.value.resource_group_id, azapi_resource.resource_group.id)
  location  = coalesce(each.value.location, var.resource_group_location)
  tags      = merge(var.tags, each.value.tags)

  body = {}

  ignore_body_changes    = length(var.ignore_body_changes.managedidentity_user_assigned_identities) > 0 ? var.ignore_body_changes.managedidentity_user_assigned_identities : null
  response_export_values = ["properties.clientId", "properties.principalId", "properties.tenantId"]
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

  depends_on = [terraform_data.stage_00_scope_complete]
}

resource "terraform_data" "stage_01_identities_complete" {
  input = {
    managed_identity_ids = {
      for key, identity in azapi_resource.managed_identity : key => identity.id
    }
  }

  depends_on = [azapi_resource.managed_identity]
}
