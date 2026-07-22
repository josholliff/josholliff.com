variable "resource_group_name" {
  description = "Name of the resource group to create for the static web app."
  type        = string
  default     = "josholliff-com-rg"
}

variable "location" {
  description = "Azure region for the resource group. Note: Static Web Apps are a global resource; this only sets the region for the containing resource group and metadata."
  type        = string
  default     = "eastus2"
}

variable "static_web_app_name" {
  description = "Name of the Azure Static Web App resource."
  type        = string
  default     = "josholliff-com"
}

variable "sku_tier" {
  description = "SKU tier for the Static Web App (Free or Standard). Custom domains work on both; Standard adds SLA, private endpoints, and more."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be either \"Free\" or \"Standard\"."
  }
}

variable "custom_domain" {
  description = "Optional apex/custom domain to attach (e.g. \"josholliff.com\"). Leave empty to skip. You must create the required DNS records at your registrar for validation to succeed."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    project   = "josholliff.com"
    managedBy = "terraform"
  }
}
