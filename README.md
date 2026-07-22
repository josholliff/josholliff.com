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

## Custom domain (optional)

Set `custom_domain` in `terraform.tfvars` (e.g. `josholliff.com`) and re-apply.
For an apex domain, read the validation token and create the matching DNS record
at your DNS provider, then re-apply so validation completes:

```bash
terraform output -raw custom_domain_validation_token
```

## Local preview

The site is plain static files — open `src/index.html` in a browser, or serve
the folder:

```bash
cd src && python3 -m http.server 8080
```
