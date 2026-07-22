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
  description = "Optional apex/custom domain to attach (e.g. \"josholliff.com\"). Leave empty to skip. When set, Terraform creates the Azure DNS zone and all required records (apex ALIAS, validation TXT, and optional www CNAME)."
  type        = string
  default     = ""
}

variable "enable_www" {
  description = "When a custom_domain is set, also attach www.<custom_domain> via a CNAME record and cname-delegation validation."
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "Name of the Azure DNS zone to create for the custom domain. Defaults to custom_domain when empty."
  type        = string
  default     = ""
}

variable "dns_zone_resource_group_name" {
  description = "Resource group in which to create the Azure DNS zone. Defaults to resource_group_name when empty. If set to a different resource group, that group must already exist."
  type        = string
  default     = ""
}

variable "manage_github_secret" {
  description = "When true, Terraform writes the Static Web App deployment token to the GitHub repo as the AZURE_STATIC_WEB_APPS_API_TOKEN Actions secret. Requires a GITHUB_TOKEN env var with rights to manage the repo's secrets."
  type        = bool
  default     = false
}

variable "github_owner" {
  description = "GitHub account/org that owns the repository (e.g. \"josholliff\"). Used only when manage_github_secret = true."
  type        = string
  default     = "josholliff"
}

variable "github_repository" {
  description = "GitHub repository name to write the deployment-token secret into (e.g. \"josholliff.com\"). Used only when manage_github_secret = true."
  type        = string
  default     = "josholliff.com"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    project   = "josholliff.com"
    managedBy = "terraform"
  }
}
