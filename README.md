# josholliff.com

Personal résumé site for Josh Olliff, hosted on **Azure Static Web Apps** and
provisioned with **Terraform**.

```
.
├── src/                     # static site content (deployed to the SWA)
│   ├── index.html
│   ├── style.css
│   ├── script.js
│   ├── resume.docx
│   └── staticwebapp.config.json
├── terraform/               # Azure infrastructure (Static Web App)
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── .github/workflows/
    └── deploy.yml           # publishes src/ to the Static Web App
```

## How it works

1. **Terraform** provisions the Azure resource group and the Static Web App
   resource, and (optionally) attaches a custom domain.
2. Terraform outputs a **deployment token** (`deployment_token`), which is the
   API key the GitHub Action uses to publish the contents of `src/`.
3. The **GitHub Actions workflow** uploads `src/` to the Static Web App on every
   push to `main`, and spins up per-PR staging environments.

## Provision the infrastructure

Prerequisites: [Terraform](https://developer.hashicorp.com/terraform) ≥ 1.5 and
the [Azure CLI](https://learn.microsoft.com/cli/azure/) (`az login`).

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan
terraform apply
```

Retrieve the deployment token after apply:

```bash
terraform output -raw deployment_token
```

## Wire up deployment

Add the token as a repository secret so the workflow can publish content:

- **Secret name:** `AZURE_STATIC_WEB_APPS_API_TOKEN`
- **Value:** the `deployment_token` output above

Push to `main` (or merge a PR) and the workflow deploys `src/` automatically.
The live URL is the `static_web_app_default_hostname` output
(`https://<name>.azurestaticapps.net`).

## Custom domain (Azure DNS)

Terraform **creates and owns the Azure DNS zone** plus the Static Web App
custom-domain registration and all records, end-to-end. Set in
`terraform.tfvars`:

```hcl
custom_domain = "josholliff.com"
enable_www    = true
# dns_zone_resource_group_name = "josholliff-com-rg"  # RG for the zone (must exist)
```

Then `terraform apply`. Terraform creates the **`azurerm_dns_zone`** and:

| Record | Name | Type  | Points to                                  |
| ------ | ---- | ----- | ------------------------------------------ |
| apex   | `@`  | A     | ALIAS → the Static Web App resource        |
| valid. | `@`  | TXT   | the apex validation token                  |
| www    | `www`| CNAME | `<name>.azurestaticapps.net`               |

Because the zone is brand new, its Azure name servers must be set as the
delegation (NS) records at your **domain registrar** before validation and TLS
can complete. Read them after apply and update the registrar:

```bash
terraform output -json dns_zone_name_servers
```

Apex validation via `dns-txt-token` is asynchronous — the provider does not wait
for it, and the TXT record is written from the token in the same apply. Once the
registrar delegation points at the Azure name servers, Azure completes validation
and issues the managed TLS certificate (NS delegation can take up to ~48h to
propagate, though it's usually much faster). The zone is created in
`resource_group_name` by default; set `dns_zone_resource_group_name` to place it
in a different (already existing) resource group.

## Local preview

The site is plain static files — open `src/index.html` in a browser, or serve
the folder:

```bash
cd src && python3 -m http.server 8080
```
