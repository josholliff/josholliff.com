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
  description = "TXT validation token for the custom domain (empty when no custom domain is configured). Create a TXT record with this value to validate apex-domain ownership."
  value       = var.custom_domain != "" ? azurerm_static_web_app_custom_domain.this[0].validation_token : null
  sensitive   = true
}
