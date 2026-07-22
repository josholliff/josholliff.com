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

# Optional custom domain. Apex domains (e.g. josholliff.com) must be validated
# with a TXT record ("dns-txt-token"); subdomains can use CNAME delegation.
# After `apply`, read the `custom_domain_validation_token` output and create the
# matching DNS record at your registrar/DNS zone before re-applying.
resource "azurerm_static_web_app_custom_domain" "this" {
  count = var.custom_domain != "" ? 1 : 0

  static_web_app_id = azurerm_static_web_app.this.id
  domain_name       = var.custom_domain
  validation_type   = "dns-txt-token"

  lifecycle {
    # Validation can take time to propagate; avoid churn on re-plan.
    ignore_changes = [validation_type]
  }
}
