resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_static_web_app" "this" {
  name                = var.static_web_app_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  sku_tier = var.sku_tier
  sku_size = var.sku_tier

  tags = var.tags
}

# Optional custom domain. When `custom_domain` is set, the apex is attached with
# TXT-token validation and (optionally) the www subdomain via CNAME delegation.
# The matching Azure DNS records are managed in dns.tf, so a single `apply`
# provisions the app, registers the domains, and writes the DNS records.
#
# dns-txt-token validation is asynchronous: the provider returns immediately with
# a validation token and does not wait for DNS to propagate, so there is no
# chicken-and-egg deadlock with the TXT record created from that token.
# The apex custom-domain resource was previously named ".this". This moved block
# renames it in state instead of destroying and recreating the existing binding.
moved {
  from = azurerm_static_web_app_custom_domain.this
  to   = azurerm_static_web_app_custom_domain.apex
}

resource "azurerm_static_web_app_custom_domain" "apex" {
  count = local.manage_custom_domain ? 1 : 0

  static_web_app_id = azurerm_static_web_app.this.id
  domain_name       = var.custom_domain
  validation_type   = "dns-txt-token"
}

# www subdomain uses CNAME delegation, which validates against the CNAME record
# managed in dns.tf (hence the explicit dependency).
resource "azurerm_static_web_app_custom_domain" "www" {
  count = local.manage_custom_domain && var.enable_www ? 1 : 0

  static_web_app_id = azurerm_static_web_app.this.id
  domain_name       = "www.${var.custom_domain}"
  validation_type   = "cname-delegation"

  depends_on = [azurerm_dns_cname_record.www]
}
