resource "azapi_resource" "managed_identity" {
  for_each = local.enabled_identities

  type      = var.resource_types.identities
  name      = each.value
  parent_id = azapi_resource.resource_group["identity_management"].id
  location  = var.location
  tags      = var.tags

  body = {}

  ignore_body_changes    = length(var.ignore_body_changes.identities) > 0 ? var.ignore_body_changes.identities : null
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
  count = local.enabled ? 1 : 0

  input = {
    identity_ids = { for key, identity in azapi_resource.managed_identity : key => identity.id }
  }

  depends_on = [azapi_resource.managed_identity]
}
