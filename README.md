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

The domain is hosted in an **Azure DNS zone**, so Terraform manages both the
Static Web App custom-domain registration and the DNS records end-to-end. Set in
`terraform.tfvars`:

```hcl
custom_domain = "josholliff.com"
enable_www    = true
# dns_zone_resource_group_name = "josholliff-com-rg"  # if the zone RG differs
```

Then `terraform apply` once. Terraform creates:

| Record | Name | Type  | Points to                                  |
| ------ | ---- | ----- | ------------------------------------------ |
| apex   | `@`  | A     | ALIAS → the Static Web App resource        |
| valid. | `@`  | TXT   | the apex validation token                  |
| www    | `www`| CNAME | `<name>.azurestaticapps.net`               |

Apex validation via `dns-txt-token` is asynchronous — the provider does not wait
for it, and the TXT record is written from the token in the same apply, so no
second run is needed. Azure completes validation and issues the managed TLS
certificate within a few minutes (apex changes can take up to ~an hour to fully
propagate). The `data.azurerm_dns_zone` lookup requires the zone to already
exist; set `dns_zone_resource_group_name` if it lives in a different RG than the
app.

## Local preview

The site is plain static files — open `src/index.html` in a browser, or serve
the folder:

```bash
cd src && python3 -m http.server 8080
```
