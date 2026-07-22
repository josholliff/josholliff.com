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

The `.github/workflows/deploy.yml` workflow uploads `src/` to the Static Web App
on every push to `main` (and builds preview environments for PRs). It needs one
repository secret, `AZURE_STATIC_WEB_APPS_API_TOKEN`, set to the deployment
token. Two ways to set it:

**Option 1 — Terraform sets it for you (recommended).** In `terraform.tfvars`:

```hcl
manage_github_secret = true
github_owner         = "josholliff"
github_repository    = "josholliff.com"
```

Export a GitHub token with rights to manage the repo's Actions secrets, then
apply:

```bash
export GITHUB_TOKEN=ghp_xxx   # PowerShell: $env:GITHUB_TOKEN="ghp_xxx"
terraform apply
```

Terraform writes the `AZURE_STATIC_WEB_APPS_API_TOKEN` secret from the app's live
token — no copy-paste, and it stays in sync on future applies.

**Option 2 — set it manually.** Copy `terraform output -raw deployment_token`
into GitHub → repo **Settings → Secrets and variables → Actions** → new secret
named `AZURE_STATIC_WEB_APPS_API_TOKEN`.

Either way, push to `main` (or merge a PR) and the workflow deploys `src/`
automatically. The live URL is the `static_web_app_default_hostname` output
(`https://<name>.azurestaticapps.net`).

## Custom domain (Azure DNS)

Terraform **creates and owns the Azure DNS zone** plus the Static Web App
custom-domain registration and all records. Because a brand-new zone gets a
brand-new set of Azure name servers, and Azure validates custom domains by
resolving them on the public internet, bringing up a **new** domain is a
**two-phase** process. Do not try to attach `www` in the same apply that creates
the zone — see the ordering below.

### Phase 1 — zone, apex, and records (before delegation)

In `terraform.tfvars`:

```hcl
custom_domain = "josholliff.com"
enable_www    = false   # IMPORTANT: keep www OFF until the domain is delegated
# dns_zone_resource_group_name = "josholliff-com-rg"  # RG for the zone (must exist)
```

```bash
terraform apply
```

Terraform creates the **`azurerm_dns_zone`** and:

| Record | Name | Type  | Points to                            |
| ------ | ---- | ----- | ------------------------------------ |
| apex   | `@`  | A     | ALIAS → the Static Web App resource  |
| valid. | `@`  | TXT   | the apex validation token            |

Apex validation (`dns-txt-token`) is **asynchronous** — the provider writes the
token, doesn't block, and Azure validates later once DNS resolves.

### Phase 2 — delegate the registrar, then attach www

1. Read the zone's assigned name servers and set them at your registrar:

   ```bash
   terraform output -json dns_zone_name_servers
   # or: az network dns zone show -g josholliff-com-rg -n josholliff.com --query nameServers -o tsv
   ```

2. Wait for delegation to go live (usually minutes, up to ~48h):

   ```bash
   nslookup -type=ns josholliff.com   # should return the *.azure-dns.* servers
   ```

3. Now flip www on and apply again:

   ```hcl
   enable_www = true
   ```
   ```bash
   terraform apply
   ```

   This adds the `www` CNAME (→ `<name>.azurestaticapps.net`) and the
   `www` custom domain. `www` uses **cname-delegation**, which Azure can only
   validate once the domain is delegated to this zone — that's why it must come
   after phase 2, or the apply will hang waiting on a CNAME that isn't publicly
   resolvable yet.

> The zone is created in `resource_group_name` by default; set
> `dns_zone_resource_group_name` to place it in a different (already existing) RG.

## Deploy the site content

Provisioning the app does **not** publish the site — until content is uploaded,
the URL shows Azure's "Congratulations on your new site!" placeholder. Publish
`src/` with the deployment token (from the terraform folder):

```bash
# PowerShell
$env:SWA_CLI_DEPLOYMENT_TOKEN = (terraform output -raw deployment_token)
npx -y @azure/static-web-apps-cli deploy ../src --env production
```

Or rely on the GitHub Actions workflow (see *Wire up deployment* above).

## Local preview

The site is plain static files — open `src/index.html` in a browser, or serve
the folder:

```bash
cd src && python3 -m http.server 8080
```
