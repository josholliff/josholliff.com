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
  description = "Optional apex/custom domain to attach (e.g. \"josholliff.com\"). Leave empty to skip. When set, the required Azure DNS records (apex ALIAS, validation TXT, and optional www CNAME) are managed automatically in an existing Azure DNS zone."
  type        = string
  default     = ""
}

variable "enable_www" {
  description = "When a custom_domain is set, also attach www.<custom_domain> via a CNAME record and cname-delegation validation."
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "Name of the existing Azure DNS zone hosting the custom domain. Defaults to custom_domain when empty."
  type        = string
  default     = ""
}

variable "dns_zone_resource_group_name" {
  description = "Resource group of the existing Azure DNS zone. Defaults to resource_group_name when empty. Set this if your DNS zone lives in a different resource group than the Static Web App."
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
