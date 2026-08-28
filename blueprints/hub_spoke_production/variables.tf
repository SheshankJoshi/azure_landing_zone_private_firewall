variable "deployment_enabled" {
  type        = bool
  default     = false
  nullable    = false
  description = "Enables Azure resources in this isolated blueprint. The default is false so placeholder values cannot be deployed."
}

variable "blueprint_approved" {
  type        = bool
  default     = false
  nullable    = false
  description = "Confirms that architecture, security, licensing, routing, and cost reviews are complete. Must be true when deployment_enabled is true."
}

variable "marketplace_values_verified" {
  type        = bool
  default     = false
  nullable    = false
  description = "Confirms that all Marketplace publisher, offer, plan, SKU, and version values were verified in the target subscriptions and regions."
}

variable "byol_terms_accepted" {
  type        = bool
  default     = false
  nullable    = false
  description = "Confirms that Palo Alto and Aviatrix licensing and Marketplace terms were accepted outside this blueprint."
}

variable "move_subscriptions_to_management_group" {
  type        = bool
  default     = false
  nullable    = false
  description = "Explicitly authorizes moving all three configured subscriptions under the selected management group. This is a high-impact governance operation."
}

variable "location" {
  type        = string
  default     = "swedencentral"
  nullable    = false
  description = "Azure region used by the placeholder topology."
}

variable "subscriptions" {
  type = object({
    connectivity        = string
    identity_management = string
    workload            = string
  })
  default = {
    connectivity        = "00000000-0000-0000-0000-000000000000"
    identity_management = "00000000-0000-0000-0000-000000000000"
    workload            = "00000000-0000-0000-0000-000000000000"
  }
  nullable    = false
  description = "Subscription IDs for the connectivity, identity/management, and workload scopes."

  validation {
    condition = !var.deployment_enabled || alltrue([
      for id in values(var.subscriptions) :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id)) &&
      id != "00000000-0000-0000-0000-000000000000"
    ])
    error_message = "Real non-placeholder subscription UUIDs are required when deployment_enabled is true."
  }
}

variable "resource_group_names" {
  type = object({
    connectivity        = string
    identity_management = string
    workload            = string
  })
  default = {
    connectivity        = "rg-connectivity-placeholder"
    identity_management = "rg-identity-management-placeholder"
    workload            = "rg-ai-workload-placeholder"
  }
  nullable    = false
  description = "Resource group names for the three-subscription topology."
}

variable "network" {
  type = object({
    hub = object({
      name          = string
      address_space = list(string)
      subnets = object({
        palo_alto_management = string
        palo_alto_untrusted  = string
        palo_alto_trusted    = string
        aviatrix_transit     = string
        private_endpoints    = string
      })
    })
    workload_spoke = object({
      name          = string
      address_space = list(string)
      subnets = object({
        application = string
        foundry     = string
      })
    })
    palo_alto_trusted_ip = string
  })
  default = {
    hub = {
      name          = "vnet-hub-placeholder"
      address_space = ["10.0.0.0/16"]
      subnets = {
        palo_alto_management = "10.0.0.0/24"
        palo_alto_untrusted  = "10.0.1.0/24"
        palo_alto_trusted    = "10.0.2.0/24"
        aviatrix_transit     = "10.0.3.0/24"
        private_endpoints    = "10.0.4.0/24"
      }
    }
    workload_spoke = {
      name          = "vnet-ai-spoke-placeholder"
      address_space = ["10.20.0.0/16"]
      subnets = {
        application = "10.20.1.0/24"
        foundry     = "10.20.2.0/24"
      }
    }
    palo_alto_trusted_ip = "10.0.2.10"
  }
  nullable    = false
  description = "Placeholder hub, workload-spoke, subnet, and trusted-appliance addressing. Review all CIDRs and appliance IPs before enabling."
}

variable "marketplace_images" {
  type = object({
    palo_alto = object({
      publisher = string
      offer     = string
      plan      = string
      sku       = string
      version   = string
    })
    aviatrix = object({
      publisher = string
      offer     = string
      plan      = string
      sku       = string
      version   = string
    })
  })
  default = {
    palo_alto = {
      publisher = "REPLACE_WITH_VERIFIED_PUBLISHER"
      offer     = "REPLACE_WITH_VERIFIED_OFFER"
      plan      = "REPLACE_WITH_VERIFIED_BYOL_PLAN"
      sku       = "REPLACE_WITH_VERIFIED_SKU"
      version   = "REPLACE_WITH_PINNED_VERSION"
    }
    aviatrix = {
      publisher = "REPLACE_WITH_VERIFIED_PUBLISHER"
      offer     = "REPLACE_WITH_VERIFIED_OFFER"
      plan      = "REPLACE_WITH_VERIFIED_PLAN"
      sku       = "REPLACE_WITH_VERIFIED_SKU"
      version   = "REPLACE_WITH_PINNED_VERSION"
    }
  }
  nullable    = false
  description = "Marketplace image coordinates. Defaults are deliberately invalid and must be replaced with values verified for every target subscription and region."

  validation {
    condition = !var.deployment_enabled || alltrue(flatten([
      for image in values(var.marketplace_images) : [
        for value in values(image) : !startswith(value, "REPLACE_") && !startswith(value, "UNVERIFIED_") && value != "latest"
      ]
    ]))
    error_message = "Every Marketplace field must be verified, must not use a placeholder prefix, and must pin an image version rather than latest."
  }
}

variable "appliance_admin_username" {
  type        = string
  default     = "azureadmin"
  nullable    = false
  description = "Administrative username for placeholder Marketplace VMs."
}

variable "appliance_admin_ssh_public_key" {
  type        = string
  default     = "REPLACE_WITH_SSH_PUBLIC_KEY"
  nullable    = false
  description = "SSH public key for Marketplace appliance VMs."

  validation {
    condition     = !var.deployment_enabled || startswith(var.appliance_admin_ssh_public_key, "ssh-")
    error_message = "A valid SSH public key is required when deployment_enabled is true."
  }
}

variable "foundry_name" {
  type        = string
  default     = "REPLACE_WITH_GLOBALLY_UNIQUE_FOUNDRY_NAME"
  nullable    = false
  description = "Globally unique name for the Foundry account placeholder."

  validation {
    condition     = !var.deployment_enabled || !startswith(var.foundry_name, "REPLACE_")
    error_message = "A reviewed globally unique Foundry account name is required before deployment."
  }
}

variable "management_group" {
  type = object({
    mode               = string
    parent_resource_id = optional(string)
    existing_id        = optional(string)
    name               = string
    display_name       = string
  })
  default = {
    mode         = "existing"
    existing_id  = "/providers/Microsoft.Management/managementGroups/REPLACE_WITH_EXISTING_ID"
    name         = "mg-ai-placeholder"
    display_name = "AI Landing Zone Placeholder"
  }
  nullable    = false
  description = "Create-or-consume management-group contract. Existing mode consumes existing_id; create mode uses name, display_name, and optional parent_resource_id."

  validation {
    condition     = contains(["create", "existing"], var.management_group.mode)
    error_message = "management_group.mode must be create or existing."
  }

  validation {
    condition = !var.deployment_enabled || var.management_group.mode == "create" || (
      var.management_group.existing_id != null &&
      !strcontains(var.management_group.existing_id, "REPLACE_") &&
      can(provider::azapi::parse_resource_id("Microsoft.Management/managementGroups", var.management_group.existing_id))
    )
    error_message = "Existing mode requires a valid non-placeholder management group resource ID before deployment."
  }
}

variable "policy_definition_ids" {
  type = map(string)
  default = {
    deny_public_network_access = "REPLACE_WITH_POLICY_DEFINITION_ID"
    require_diagnostics        = "REPLACE_WITH_POLICY_DEFINITION_ID"
    require_user_assigned_id   = "REPLACE_WITH_POLICY_DEFINITION_ID"
  }
  nullable    = false
  description = "Policy definition or initiative resource IDs assigned only after identity attachment and RBAC complete."

  validation {
    condition = !var.deployment_enabled || alltrue([
      for id in values(var.policy_definition_ids) : !startswith(id, "REPLACE_")
    ])
    error_message = "All policy definition IDs must be replaced before deployment."
  }
}

variable "tags" {
  type = map(string)
  default = {
    environment = "placeholder"
    managed_by  = "terraform"
    blueprint   = "hub-spoke-production"
  }
  nullable    = false
  description = "Tags applied to resources that support tags."
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to every supported AzAPI resource in the blueprint."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to every supported AzAPI resource in the blueprint."
}

variable "ignore_body_changes" {
  type = map(list(string))
  default = {
    resource_groups                = []
    management_groups              = []
    management_group_subscriptions = []
    identities                     = []
    virtual_networks               = []
    subnets                        = []
    network_security_groups        = []
    application_security_groups    = []
    public_ip_addresses            = []
    load_balancers                 = []
    network_interfaces             = []
    virtual_machines               = []
    route_tables                   = []
    peerings                       = []
    private_dns_zones              = []
    foundry                        = []
    private_endpoints              = []
    log_analytics                  = []
    sentinel                       = []
    identity_attachments           = []
    role_assignments               = []
    policy_assignments             = []
  }
  nullable    = false
  description = "Body-relative AzAPI paths ignored by resource family. Paths use dot notation; ignored configuration is not sent to Azure, and changes take effect only after apply."
}

variable "resource_types" {
  type = map(string)
  default = {
    resource_groups                = "Microsoft.Resources/resourceGroups@2024-03-01"
    management_groups              = "Microsoft.Management/managementGroups@2023-04-01"
    management_group_subscriptions = "Microsoft.Management/managementGroups/subscriptions@2023-04-01"
    identities                     = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
    virtual_networks               = "Microsoft.Network/virtualNetworks@2024-05-01"
    subnets                        = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
    network_security_groups        = "Microsoft.Network/networkSecurityGroups@2024-05-01"
    application_security_groups    = "Microsoft.Network/applicationSecurityGroups@2024-05-01"
    public_ip_addresses            = "Microsoft.Network/publicIPAddresses@2024-05-01"
    load_balancers                 = "Microsoft.Network/loadBalancers@2024-05-01"
    network_interfaces             = "Microsoft.Network/networkInterfaces@2024-05-01"
    virtual_machines               = "Microsoft.Compute/virtualMachines@2024-11-01"
    route_tables                   = "Microsoft.Network/routeTables@2024-05-01"
    peerings                       = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01"
    private_dns_zones              = "Microsoft.Network/privateDnsZones@2024-06-01"
    private_dns_vnet_links         = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01"
    foundry                        = "Microsoft.CognitiveServices/accounts@2025-06-01"
    private_endpoints              = "Microsoft.Network/privateEndpoints@2024-05-01"
    log_analytics                  = "Microsoft.OperationalInsights/workspaces@2023-09-01"
    sentinel                       = "Microsoft.SecurityInsights/onboardingStates@2024-03-01"
    identity_attachments           = "Microsoft.CognitiveServices/accounts@2025-06-01"
    role_assignments               = "Microsoft.Authorization/roleAssignments@2022-04-01"
    policy_assignments             = "Microsoft.Authorization/policyAssignments@2024-04-01"
  }
  nullable    = false
  description = "AzAPI resource types and API versions used by this isolated blueprint."
}
