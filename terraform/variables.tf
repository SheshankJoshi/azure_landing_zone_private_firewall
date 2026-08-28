variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that will receive the deployment."
  default     = "ai-lz-rg-01"
  nullable    = false
}

variable "resource_group_location" {
  type        = string
  description = "Azure region for the resource group."
  default     = "swedencentral"
  nullable    = false
}

variable "deployment_name" {
  type        = string
  description = "Name of the ARM deployment record."
  default     = "ai-landing-zone"
  nullable    = false
}

variable "portal_template_path" {
  type        = string
  description = "Path, relative to this Terraform root, to the legacy Portal ARM template. This compatibility input remains supported while discrete Terraform resources become authoritative."
  default     = "../portal/template.json"
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  description = "Controls the template telemetry flag."
  default     = true
  nullable    = false
}

variable "portal_parameters" {
  type        = map(any)
  description = "Additional parameters passed unchanged to the legacy Portal ARM template. Typed Terraform inputs will take precedence as the compatibility adapter is expanded."
  default     = {}
  nullable    = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the resource group."
  default     = {}
  nullable    = false
}

variable "subscription_id" {
  type        = string
  default     = null
  description = "Subscription ID in which the compatibility resource group and legacy ARM deployment are created. When null, the subscription from the active AzAPI client configuration is used."

  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "`subscription_id` must be null or a valid UUID."
  }
}

variable "migrate_legacy_azurerm_state" {
  type        = bool
  default     = false
  nullable    = false
  description = "Imports the existing AzureRM-managed resource group and ARM deployment into their AzAPI addresses after the old state addresses are removed without destroying Azure resources. Enable only for the first migration plan of an existing environment."
}

variable "resource_types" {
  type = object({
    resources_resource_groups                = optional(string, "Microsoft.Resources/resourceGroups@2024-03-01")
    resources_deployments                    = optional(string, "Microsoft.Resources/deployments@2024-03-01")
    managedidentity_user_assigned_identities = optional(string, "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31")
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the compatibility deployment.

- `resources_resource_groups` - Resource type and API version for the deployment resource group.
- `resources_deployments` - Resource type and API version for the legacy ARM deployment.
- `managedidentity_user_assigned_identities` - Resource type and API version for user-assigned managed identities.
DESCRIPTION
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every supported AzAPI resource declared by this Terraform root. Defaults to `null`, which uses provider behavior.

- `error_message_regex` - Error-message patterns that trigger a retry.
- `interval_seconds` - Initial interval between retries in seconds.
- `max_interval_seconds` - Maximum interval between retries in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Per-operation timeouts applied to every supported AzAPI resource declared by this Terraform root. Values are Go duration strings.

- `create` - Timeout for create operations.
- `read` - Timeout for read operations.
- `update` - Timeout for update operations.
- `delete` - Timeout for delete operations.
DESCRIPTION
}

variable "ignore_body_changes" {
  type = object({
    resources_resource_groups                = optional(list(string), [])
    resources_deployments                    = optional(list(string), [])
    managedidentity_user_assigned_identities = optional(list(string), [])
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Body-relative paths ignored for each AzAPI resource. Paths use dot notation. Ignored configuration is not sent to Azure until its path is removed, and changes to this setting take effect only after apply.

- `resources_resource_groups` - Paths ignored on the resource group.
- `resources_deployments` - Paths ignored on the legacy ARM deployment.
- `managedidentity_user_assigned_identities` - Paths ignored on user-assigned managed identities.
DESCRIPTION
}
