locals {
  manage_custom_domain = var.custom_domain != ""

  # The DNS zone name defaults to the apex domain; override only if the zone is
  # named differently. The zone's resource group defaults to the app's RG.
  dns_zone_name = coalesce(var.dns_zone_name, var.custom_domain)
  dns_zone_rg   = coalesce(var.dns_zone_resource_group_name, var.resource_group_name)
}

# Reference the EXISTING Azure DNS zone that your registrar is already delegated
# to. We do not create the zone, because creating a new one would generate a
# different name-server set and break the delegation you already have in place.
# Records below are added into this existing zone.
data "azurerm_dns_zone" "this" {
  count               = local.manage_custom_domain ? 1 : 0
  name                = local.dns_zone_name
  resource_group_name = local.dns_zone_rg
}

# Apex routing: an ALIAS A record at the zone apex pointing at the Static Web App
# resource. This is the Azure DNS equivalent of the "ALIAS" record Static Web
# Apps expects for a root domain, and keeps global distribution (unlike a plain
# A record to a single IP).
resource "azurerm_dns_a_record" "apex" {
  count               = local.manage_custom_domain ? 1 : 0
  name                = "@"
  zone_name           = data.azurerm_dns_zone.this[0].name
  resource_group_name = local.dns_zone_rg
  ttl                 = 300
  target_resource_id  = azurerm_static_web_app.this.id
  tags                = var.tags
}

# Apex ownership validation: TXT record at the apex holding the token issued by
# the custom-domain registration.
resource "azurerm_dns_txt_record" "apex_validation" {
  count               = local.manage_custom_domain ? 1 : 0
  name                = "@"
  zone_name           = data.azurerm_dns_zone.this[0].name
  resource_group_name = local.dns_zone_rg
  ttl                 = 300

  record {
    value = azurerm_static_web_app_custom_domain.apex[0].validation_token
  }

  tags = var.tags
}

# www subdomain -> the app's default hostname (used for cname-delegation).
resource "azurerm_dns_cname_record" "www" {
  count               = local.manage_custom_domain && var.enable_www ? 1 : 0
  name                = "www"
  zone_name           = data.azurerm_dns_zone.this[0].name
  resource_group_name = local.dns_zone_rg
  ttl                 = 300
  record              = azurerm_static_web_app.this.default_host_name
  tags                = var.tags
}
