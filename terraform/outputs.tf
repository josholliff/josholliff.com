output "static_web_app_default_hostname" {
  description = "The default *.azurestaticapps.net hostname for the site."
  value       = azurerm_static_web_app.this.default_host_name
}

output "static_web_app_id" {
  description = "Resource ID of the Static Web App."
  value       = azurerm_static_web_app.this.id
}

output "deployment_token" {
  description = "API key used by the deployment (GitHub Action / CLI) to publish content. Store as the AZURE_STATIC_WEB_APPS_API_TOKEN secret."
  value       = azurerm_static_web_app.this.api_key
  sensitive   = true
}

output "custom_domain_validation_token" {
  description = "TXT validation token for the apex custom domain (null when no custom domain is configured). The matching TXT record is managed automatically in dns.tf."
  value       = local.manage_custom_domain ? azurerm_static_web_app_custom_domain.apex[0].validation_token : null
  sensitive   = true
}

output "dns_zone_name_servers" {
  description = "Name servers assigned to the created Azure DNS zone. Set these as the NS records at your domain registrar so the zone becomes authoritative."
  value       = local.manage_custom_domain ? azurerm_dns_zone.this[0].name_servers : []
}

output "custom_domains" {
  description = "Custom domains attached to the Static Web App."
  value = local.manage_custom_domain ? compact([
    var.custom_domain,
    var.enable_www ? "www.${var.custom_domain}" : "",
  ]) : []
}
