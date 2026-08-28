variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that will receive the deployment."
  default     = "ai-lz-rg-01"
}

variable "resource_group_location" {
  type        = string
  description = "Azure region for the resource group."
  default     = "swedencentral"
}

variable "deployment_name" {
  type        = string
  description = "Name of the ARM deployment record."
  default     = "ai-landing-zone"
}

variable "portal_template_path" {
  type        = string
  description = "Path to the portal ARM template that defines the landing zone."
  default     = "../portal/template.json"
}

variable "enable_telemetry" {
  type        = bool
  description = "Controls the template telemetry flag."
  default     = true
}

variable "portal_parameters" {
  type        = map(any)
  description = "Additional portal template parameters to pass through."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the resource group."
  default     = {}
}
