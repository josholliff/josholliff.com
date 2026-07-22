terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # Remote state is recommended for team use / CI. Configure the backend by
  # supplying values via `terraform init -backend-config=...` or a backend
  # block, then uncomment below.
  #
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatejosholliff"
  #   container_name       = "tfstate"
  #   key                  = "josholliff.com.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

# Auth via the GITHUB_TOKEN env var (a PAT with `repo` scope, or a fine-grained
# token with read/write on Actions secrets for the repository). Only used when
# manage_github_secret = true.
provider "github" {
  owner = var.github_owner
}
