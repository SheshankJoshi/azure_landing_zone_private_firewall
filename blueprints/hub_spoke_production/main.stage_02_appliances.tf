resource "azapi_resource" "palo_alto_public_ip" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.public_ip_addresses
  name      = "pip-palo-alto-ingress-placeholder"
  parent_id = azapi_resource.resource_group["connectivity"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      publicIPAllocationMethod = "Static"
    }
    sku = {
      name = "Standard"
      tier = "Regional"
    }
    zones = ["1", "2", "3"]
  }

  ignore_body_changes    = length(var.ignore_body_changes.public_ip_addresses) > 0 ? var.ignore_body_changes.public_ip_addresses : null
  response_export_values = ["properties.ipAddress"]
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

resource "azapi_resource" "palo_alto_external_load_balancer" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.load_balancers
  name      = "lb-palo-alto-external-placeholder"
  parent_id = azapi_resource.resource_group["connectivity"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      backendAddressPools = [
        {
          name = "palo-alto-untrusted"
        }
      ]
      frontendIPConfigurations = [
        {
          name = "public-ingress"
          properties = {
            publicIPAddress = {
              id = azapi_resource.palo_alto_public_ip[0].id
            }
          }
        }
      ]
      loadBalancingRules = [
        {
          name = "ha-ports"
          properties = {
            backendAddressPool = {
              id = "${azapi_resource.resource_group["connectivity"].id}/providers/Microsoft.Network/loadBalancers/lb-palo-alto-external-placeholder/backendAddressPools/palo-alto-untrusted"
            }
            backendPort         = 0
            disableOutboundSnat = true
            enableFloatingIP    = true
            frontendIPConfiguration = {
              id = "${azapi_resource.resource_group["connectivity"].id}/providers/Microsoft.Network/loadBalancers/lb-palo-alto-external-placeholder/frontendIPConfigurations/public-ingress"
            }
            frontendPort         = 0
            idleTimeoutInMinutes = 4
            loadDistribution     = "Default"
            probe = {
              id = "${azapi_resource.resource_group["connectivity"].id}/providers/Microsoft.Network/loadBalancers/lb-palo-alto-external-placeholder/probes/tcp-health-placeholder"
            }
            protocol = "All"
          }
        }
      ]
      probes = [
        {
          name = "tcp-health-placeholder"
          properties = {
            intervalInSeconds = 5
            numberOfProbes    = 2
            port              = 22
            protocol          = "Tcp"
          }
        }
      ]
    }
    sku = {
      name = "Standard"
      tier = "Regional"
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.load_balancers) > 0 ? var.ignore_body_changes.load_balancers : null
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

resource "azapi_resource" "palo_alto_internal_load_balancer" {
  count = local.enabled ? 1 : 0

  type      = var.resource_types.load_balancers
  name      = "lb-palo-alto-internal-placeholder"
  parent_id = azapi_resource.resource_group["connectivity"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      backendAddressPools = [
        {
          name = "palo-alto-trusted"
        }
      ]
      frontendIPConfigurations = [
        {
          name = "trusted"
          properties = {
            privateIPAddress          = var.network.palo_alto_trusted_ip
            privateIPAllocationMethod = "Static"
            subnet = {
              id = azapi_resource.subnet["hub_palo_alto_trusted"].id
            }
          }
        }
      ]
      loadBalancingRules = [
        {
          name = "ha-ports"
          properties = {
            backendAddressPool = {
              id = "${azapi_resource.resource_group["connectivity"].id}/providers/Microsoft.Network/loadBalancers/lb-palo-alto-internal-placeholder/backendAddressPools/palo-alto-trusted"
            }
            backendPort      = 0
            enableFloatingIP = true
            frontendIPConfiguration = {
              id = "${azapi_resource.resource_group["connectivity"].id}/providers/Microsoft.Network/loadBalancers/lb-palo-alto-internal-placeholder/frontendIPConfigurations/trusted"
            }
            frontendPort = 0
            probe = {
              id = "${azapi_resource.resource_group["connectivity"].id}/providers/Microsoft.Network/loadBalancers/lb-palo-alto-internal-placeholder/probes/tcp-health-placeholder"
            }
            protocol = "All"
          }
        }
      ]
      probes = [
        {
          name = "tcp-health-placeholder"
          properties = {
            intervalInSeconds = 5
            numberOfProbes    = 2
            port              = 22
            protocol          = "Tcp"
          }
        }
      ]
    }
    sku = {
      name = "Standard"
      tier = "Regional"
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.load_balancers) > 0 ? var.ignore_body_changes.load_balancers : null
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

resource "azapi_resource" "appliance_network_interface" {
  for_each = local.enabled_appliance_nics

  type      = var.resource_types.network_interfaces
  name      = each.value.name
  parent_id = azapi_resource.resource_group["connectivity"].id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      enableAcceleratedNetworking = false
      enableIPForwarding          = each.value.role != "management"
      ipConfigurations = [
        {
          name = "ipconfig-${each.value.role}"
          properties = merge({
            privateIPAllocationMethod = "Dynamic"
            subnet = {
              id = azapi_resource.subnet[each.value.subnet_key].id
            }
            }, each.value.role == "untrusted" ? {
            loadBalancerBackendAddressPools = [
              {
                id = "${azapi_resource.palo_alto_external_load_balancer[0].id}/backendAddressPools/palo-alto-untrusted"
              }
            ]
            } : each.value.role == "trusted" ? {
            loadBalancerBackendAddressPools = [
              {
                id = "${azapi_resource.palo_alto_internal_load_balancer[0].id}/backendAddressPools/palo-alto-trusted"
              }
            ]
          } : {})
        }
      ]
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.network_interfaces) > 0 ? var.ignore_body_changes.network_interfaces : null
  response_export_values = ["properties.ipConfigurations"]
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
    azapi_resource.palo_alto_external_load_balancer,
    azapi_resource.palo_alto_internal_load_balancer,
  ]
}

resource "azapi_resource" "appliance_virtual_machine" {
  for_each = local.enabled_appliance_nodes

  type      = var.resource_types.virtual_machines
  name      = each.value.name
  parent_id = azapi_resource.resource_group["connectivity"].id
  location  = var.location
  tags      = var.tags

  body = {
    plan = {
      name      = var.marketplace_images[each.value.image_key].plan
      product   = var.marketplace_images[each.value.image_key].offer
      publisher = var.marketplace_images[each.value.image_key].publisher
    }
    properties = {
      hardwareProfile = {
        vmSize = each.value.size
      }
      networkProfile = {
        networkInterfaces = [
          for nic_key, nic in local.appliance_nics : {
            id = azapi_resource.appliance_network_interface[nic_key].id
            properties = {
              primary = nic.role == "management"
            }
          } if nic.node_key == each.key
        ]
      }
      osProfile = {
        adminUsername = var.appliance_admin_username
        computerName  = substr(each.value.name, 0, 15)
        linuxConfiguration = {
          disablePasswordAuthentication = true
          ssh = {
            publicKeys = [
              {
                keyData = var.appliance_admin_ssh_public_key
                path    = "/home/${var.appliance_admin_username}/.ssh/authorized_keys"
              }
            ]
          }
        }
      }
      storageProfile = {
        imageReference = {
          offer     = var.marketplace_images[each.value.image_key].offer
          publisher = var.marketplace_images[each.value.image_key].publisher
          sku       = var.marketplace_images[each.value.image_key].sku
          version   = var.marketplace_images[each.value.image_key].version
        }
        osDisk = {
          createOption = "FromImage"
          managedDisk = {
            storageAccountType = "Premium_LRS"
          }
        }
      }
    }
    zones = [each.value.zone]
  }

  ignore_body_changes    = length(var.ignore_body_changes.virtual_machines) > 0 ? var.ignore_body_changes.virtual_machines : null
  response_export_values = ["properties.provisioningState"]
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
    terraform_data.stage_01_identities_complete,
    azapi_resource.appliance_network_interface,
  ]
}

resource "azapi_update_resource" "workload_route_table_association" {
  count = local.enabled ? 1 : 0

  type        = var.resource_types.subnets
  resource_id = azapi_resource.subnet["workload_application"].id

  body = {
    properties = {
      addressPrefix = var.network.workload_spoke.subnets.application
      networkSecurityGroup = {
        id = azapi_resource.workload_network_security_group[0].id
      }
      routeTable = {
        id = azapi_resource.workload_route_table[0].id
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

  depends_on = [
    azapi_resource.appliance_virtual_machine,
    azapi_resource.workload_network_security_group,
  ]
}
