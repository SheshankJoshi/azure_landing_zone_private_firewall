locals {
  enabled = (
    var.deployment_enabled &&
    var.blueprint_approved &&
    var.marketplace_values_verified &&
    var.byol_terms_accepted &&
    var.move_subscriptions_to_management_group
  )
  pinned_env0_deployment_principal_id = "REPLACE_IN_SOURCE_WITH_PINNED_ENV0_PRINCIPAL_ID"

  resource_groups = {
    connectivity = {
      name            = var.resource_group_names.connectivity
      subscription_id = var.subscriptions.connectivity
    }
    identity_management = {
      name            = var.resource_group_names.identity_management
      subscription_id = var.subscriptions.identity_management
    }
    workload = {
      name            = var.resource_group_names.workload
      subscription_id = var.subscriptions.workload
    }
  }

  enabled_resource_groups          = local.enabled ? local.resource_groups : {}
  enabled_subscription_enrollments = local.enabled && var.move_subscriptions_to_management_group ? var.subscriptions : {}

  identity_definitions = {
    palo_alto_automation = "id-palo-alto-placeholder"
    aviatrix             = "id-aviatrix-placeholder"
    foundry              = "id-foundry-placeholder"
    application          = "id-application-placeholder"
    monitoring           = "id-monitoring-placeholder"
    deployment           = "id-env0-deployment-placeholder"
  }

  enabled_identities = local.enabled ? local.identity_definitions : {}

  virtual_network_definitions = {
    hub = {
      name               = var.network.hub.name
      resource_group_key = "connectivity"
      address_space      = var.network.hub.address_space
    }
    workload = {
      name               = var.network.workload_spoke.name
      resource_group_key = "workload"
      address_space      = var.network.workload_spoke.address_space
    }
  }

  enabled_virtual_networks = local.enabled ? local.virtual_network_definitions : {}

  subnets = merge(
    {
      for key, prefix in var.network.hub.subnets : "hub_${key}" => {
        name           = replace(key, "_", "-")
        vnet_key       = "hub"
        address_prefix = prefix
      }
    },
    {
      for key, prefix in var.network.workload_spoke.subnets : "workload_${key}" => {
        name           = replace(key, "_", "-")
        vnet_key       = "workload"
        address_prefix = prefix
      }
    }
  )

  appliance_nodes = {
    palo_alto_primary = {
      name         = "vm-palo-alto-primary-placeholder"
      image_key    = "palo_alto"
      identity_key = "palo_alto_automation"
      subnet_key   = "hub_palo_alto_management"
      size         = "Standard_D5_v2"
      zone         = "1"
    }
    palo_alto_secondary = {
      name         = "vm-palo-alto-secondary-placeholder"
      image_key    = "palo_alto"
      identity_key = "palo_alto_automation"
      subnet_key   = "hub_palo_alto_management"
      size         = "Standard_D5_v2"
      zone         = "2"
    }
    aviatrix_controller = {
      name         = "vm-aviatrix-controller-placeholder"
      image_key    = "aviatrix"
      identity_key = "aviatrix"
      subnet_key   = "hub_aviatrix_transit"
      size         = "Standard_D4s_v5"
      zone         = "1"
    }
    aviatrix_transit_primary = {
      name         = "vm-aviatrix-transit-primary-placeholder"
      image_key    = "aviatrix"
      identity_key = "aviatrix"
      subnet_key   = "hub_aviatrix_transit"
      size         = "Standard_D4s_v5"
      zone         = "1"
    }
    aviatrix_transit_secondary = {
      name         = "vm-aviatrix-transit-secondary-placeholder"
      image_key    = "aviatrix"
      identity_key = "aviatrix"
      subnet_key   = "hub_aviatrix_transit"
      size         = "Standard_D4s_v5"
      zone         = "2"
    }
  }

  enabled_appliance_nodes = local.enabled ? local.appliance_nodes : {}

  appliance_nics = merge([
    for node_key, node in local.appliance_nodes : {
      for nic_role in(node.image_key == "palo_alto" ? ["management", "untrusted", "trusted"] : ["management"]) :
      "${node_key}_${nic_role}" => {
        name       = "nic-${replace(node.name, "vm-", "")}-${nic_role}"
        node_key   = node_key
        role       = nic_role
        subnet_key = node.image_key == "palo_alto" ? "hub_palo_alto_${nic_role}" : node.subnet_key
      }
    }
  ]...)

  enabled_appliance_nics = local.enabled ? local.appliance_nics : {}

  private_dns_zones = toset([
    "privatelink.api.azureml.ms",
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
  ])

  enabled_private_dns_zones = local.enabled ? local.private_dns_zones : toset([])
}

check "deployment_gate" {
  assert {
    condition = !var.deployment_enabled || (
      var.blueprint_approved &&
      var.marketplace_values_verified &&
      var.byol_terms_accepted &&
      var.move_subscriptions_to_management_group
    )
    error_message = "Deployment is blocked until architecture approval, Marketplace verification, BYOL acceptance, and subscription-movement approval are all true."
  }
}
