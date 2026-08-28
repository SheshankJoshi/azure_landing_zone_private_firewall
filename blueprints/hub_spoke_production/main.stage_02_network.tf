resource "azapi_resource" "virtual_network" {
  for_each = local.enabled_virtual_networks

  type      = var.resource_types.virtual_networks
  name      = each.value.name
  parent_id = azapi_resource.resource_group[each.value.resource_group_key].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      addressSpace = {
        addressPrefixes = each.value.address_space
      }
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.virtual_networks) > 0 ? var.ignore_body_changes.virtual_networks : null
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

resource "azapi_resource" "subnet" {
  for_each = local.enabled ? local.subnets : {}

  type      = var.resource_types.subnets
  name      = each.value.name
  parent_id = azapi_resource.virtual_network[each.value.vnet_key].id

  body = {
    properties = {
      addressPrefix                     = each.value.address_prefix
      defaultOutboundAccess             = false
      privateEndpointNetworkPolicies    = each.key == "hub_private_endpoints" ? "Disabled" : "Enabled"
      privateLinkServiceNetworkPolicies = "Enabled"
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.subnets) > 0 ? var.ignore_body_changes.subnets : null
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

resource "azapi_resource" "hub_to_workload_peering" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.peerings
  name      = "hub-to-workload"
  parent_id = azapi_resource.virtual_network["hub"].id

  body = {
    properties = {
      allowForwardedTraffic     = true
      allowGatewayTransit       = true
      allowVirtualNetworkAccess = true
      remoteVirtualNetwork = {
        id = azapi_resource.virtual_network["workload"].id
      }
      useRemoteGateways = false
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.peerings) > 0 ? var.ignore_body_changes.peerings : null
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

  depends_on = [azapi_resource.subnet]
}

resource "azapi_resource" "workload_to_hub_peering" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.peerings
  name      = "workload-to-hub"
  parent_id = azapi_resource.virtual_network["workload"].id

  body = {
    properties = {
      allowForwardedTraffic     = true
      allowGatewayTransit       = false
      allowVirtualNetworkAccess = true
      remoteVirtualNetwork = {
        id = azapi_resource.virtual_network["hub"].id
      }
      useRemoteGateways = false
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.peerings) > 0 ? var.ignore_body_changes.peerings : null
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

  depends_on = [azapi_resource.hub_to_workload_peering]
}

resource "azapi_resource" "workload_route_table" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.route_tables
  name      = "rt-workload-forced-inspection-placeholder"
  parent_id = azapi_resource.resource_group["workload"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      disableBgpRoutePropagation = false
      routes = [
        {
          name = "default-through-palo-alto"
          properties = {
            addressPrefix    = "0.0.0.0/0"
            nextHopIpAddress = var.network.palo_alto_trusted_ip
            nextHopType      = "VirtualAppliance"
          }
        }
      ]
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.route_tables) > 0 ? var.ignore_body_changes.route_tables : null
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

  depends_on = [azapi_resource.workload_to_hub_peering]
}
