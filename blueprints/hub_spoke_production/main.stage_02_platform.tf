resource "azapi_resource" "log_analytics_workspace" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.log_analytics
  name      = "law-ai-landing-zone-placeholder"
  parent_id = azapi_resource.resource_group["identity_management"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      features = {
        enableLogAccessUsingOnlyResourcePermissions = true
      }
      publicNetworkAccessForIngestion = "Disabled"
      publicNetworkAccessForQuery     = "Disabled"
      retentionInDays                 = 90
      sku = {
        name = "PerGB2018"
      }
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.log_analytics) > 0 ? var.ignore_body_changes.log_analytics : null
  response_export_values = ["properties.customerId"]
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

resource "azapi_resource" "sentinel_onboarding" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.sentinel
  name      = "default"
  parent_id = azapi_resource.log_analytics_workspace[0].id

  body = {
    properties = {}
  }

  ignore_body_changes    = length(var.ignore_body_changes.sentinel) > 0 ? var.ignore_body_changes.sentinel : null
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
}

resource "azapi_resource" "foundry" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.foundry
  name      = var.foundry_name
  parent_id = azapi_resource.resource_group["workload"].id
  location  = var.location
  tags      = var.tags

  body = {
    kind = "AIServices"
    properties = {
      allowProjectManagement = true
      customSubDomainName    = var.foundry_name
      publicNetworkAccess    = "Disabled"
    }
    sku = {
      name = "S0"
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.foundry) > 0 ? var.ignore_body_changes.foundry : null
  response_export_values = ["properties.endpoint"]
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

resource "azapi_resource" "private_dns_zone" {
  for_each = local.enabled_private_dns_zones

  type      = var.resource_types.private_dns_zones
  name      = each.value
  parent_id = azapi_resource.resource_group["connectivity"].id
  location  = "global"
  tags      = var.tags

  body = {
    properties = {}
  }

  ignore_body_changes    = length(var.ignore_body_changes.private_dns_zones) > 0 ? var.ignore_body_changes.private_dns_zones : null
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

  depends_on = [azapi_resource.virtual_network]
}

resource "azapi_resource" "private_dns_hub_link" {
  for_each = local.enabled_private_dns_zones

  type      = var.resource_types.private_dns_vnet_links
  name      = "hub-link"
  parent_id = azapi_resource.private_dns_zone[each.value].id
  location  = "global"
  tags      = var.tags

  body = {
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azapi_resource.virtual_network["hub"].id
      }
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.private_dns_zones) > 0 ? var.ignore_body_changes.private_dns_zones : null
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
}

resource "azapi_resource" "foundry_private_endpoint" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.private_endpoints
  name      = "pe-foundry-placeholder"
  parent_id = azapi_resource.resource_group["connectivity"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      privateLinkServiceConnections = [
        {
          name = "foundry"
          properties = {
            groupIds             = ["account"]
            privateLinkServiceId = azapi_resource.foundry[0].id
          }
        }
      ]
      subnet = {
        id = azapi_resource.subnet["hub_private_endpoints"].id
      }
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.private_endpoints) > 0 ? var.ignore_body_changes.private_endpoints : null
  response_export_values = ["properties.networkInterfaces"]
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

  depends_on = [
    azapi_resource.private_dns_hub_link,
    azapi_update_resource.workload_route_table_association,
  ]
}

resource "terraform_data" "stage_02_resources_complete" {
  count = local.enabled ? 1 : 0

  input = {
    appliance_ids       = { for key, appliance in azapi_resource.appliance_virtual_machine : key => appliance.id }
    foundry_id          = azapi_resource.foundry[0].id
    private_endpoint_id = azapi_resource.foundry_private_endpoint[0].id
    sentinel_id         = azapi_resource.sentinel_onboarding[0].id
  }

  depends_on = [
    azapi_resource.appliance_virtual_machine,
    azapi_resource.application_security_group,
    azapi_resource.foundry_private_endpoint,
    azapi_resource.sentinel_onboarding,
    azapi_resource.workload_network_security_group,
  ]
}
