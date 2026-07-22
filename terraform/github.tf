# Publish the Static Web App deployment token to the GitHub repository as an
# Actions secret, so the deploy.yml workflow can upload the site on push to main.
# Gated behind manage_github_secret so `apply` doesn't require a GitHub token
# unless you want Terraform to manage the secret.
resource "github_actions_secret" "swa_deployment_token" {
  count = var.manage_github_secret ? 1 : 0

  repository      = var.github_repository
  secret_name     = "AZURE_STATIC_WEB_APPS_API_TOKEN"
  plaintext_value = azurerm_static_web_app.this.api_key
}
