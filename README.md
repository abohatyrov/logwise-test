# FastAPI → Google Cloud Run (Terraform + GitHub Actions + WIF)

This repository builds and deploys a simple FastAPI application to **Google Cloud Run**.  
Infrastructure is managed with **Terraform**, and deployments are automated via **GitHub Actions** using **Workload Identity Federation (WIF)** - no static JSON keys.

---

## Architecture Overview

**Runtime path**
- `app/` container → pushed to **Artifact Registry (Docker)**.
- Cloud Run (v2) service runs that image.
- Service is private by default (no `allUsers` invoker binding in Terraform).

**CI/CD path**
- GitHub Actions uses **OIDC** → exchanges for Google credentials via **WIF**.
- Job builds & pushes image → runs `terraform apply` to update Cloud Run with the new tag.

**Terraform state**
- Remote state stored in a GCS bucket (configured in `terraform/backend.tf`).

Repo structure (top-level):
```
📦logwise-test
 ┣ 📂.github
 ┃ ┗ 📂workflows  # CI/CD pipeline (GitHub Actions)
 ┣ 📂app          # FastAPI app & Dockerfile
 ┣ 📂terraform    # IaC (Cloud Run, Artifact Registry, etc.)
 ┣ 📜.gitignore
 ┗ 📜README.md
```
---

## What Terraform Creates (incl. WIF & IAM)

Terraform provisions the full stack end-to-end:

- **Artifact Registry** (Docker) repository.
- **Cloud Run (v2)** service and revision traffic.
- **Workload Identity Federation (WIF)**:
  - **Workload Identity Pool** and **OIDC Provider** (issuer: `https://token.actions.githubusercontent.com`).
  - **Direct WIF**: project IAM bindings that grant roles **directly** to your GitHub repo principal
    (`principalSet://iam.googleapis.com/<pool>/attribute.repository/ORG/REPO`), e.g.:
    - `roles/run.admin`
    - `roles/artifactregistry.writer`
- **Cloud Run invoker IAM**.

> ❗**Permissions for the very first apply**:  
> The identity running the **initial** `terraform apply` must be able to create WIF resources and update project IAM (e.g., `roles/iam.workloadIdentityPoolAdmin` and `roles/resourcemanager.projectIamAdmin`).  
> After bootstrap, CI runs with WIF and no keys.

---

## Why no Terraform modules (on purpose)

This repo is intentionally **flat** and “single-stack” for clarity and reviewability:

- **Small scope** (one service) → modules would add ceremony without real reuse yet.
- **Traceability** → a reviewer sees every resource in one place.
- **Faster bootstrap** → fewer moving parts while you validate CI/WIF and app startup.

**Trade-offs / when to modularize later**
- If you add environments (dev/stage/prod), split into `envs/` + reusable modules (e.g., `cloud_run_service`, `artifact_registry`, `wif`).
- If you create multiple services, extract shared bits into modules and use `for_each`/`terragrunt`/`workspaces` as you prefer.

---

## Prerequisites

1. **GCP project with billing enabled.**

2. **Terraform state bucket** (once):

```bash
gsutil mb -l <REGION> gs://<YOUR_TFSTATE_BUCKET>
```

Set the bucket in `terraform/backend.tf`.

3. **Required APIs** in your project:

* `run.googleapis.com`
* `artifactregistry.googleapis.com`

4. **Workload Identity Federation (WIF)**

You need a WIF **pool + provider** and a principal that can deploy. Two supported patterns:

* **Direct WIF (no SA)**
  Admin grants the repo principal the needed roles directly at project/service scope.
  In the workflow we **omit** `service_account` and only pass `workload_identity_provider` (+ `project_id`).

---

## Using the `trf` script to run Terraform

This repo includes a small helper script **`trf`** that wraps `terraform init/plan/apply` with the correct **workspace** and **tfvars** for you.

Typical usage:

```bash
# Initialize backend/state for sandbox (configures bucket/prefix and selects the workspace)
./trf sbx init

# See the plan for sandbox
./trf sbx plan

# Apply sandbox with its tfvars
./trf sbx apply
```

**Notes**

* The script selects/creates the requested workspace (e.g., `sandbox`) and uses `terraform/vars/<workspace>.tfvars`.
* If you add more environments later, just create `vars/<env>.tfvars` and call `./trf <env> <cmd>`.
* Open the script to see the exact commands/flags it supports.

---

## Configuration

### Terraform variables

Key inputs (exact names from the Terraform code):

* `project_id` (string) – your GCP project
* `region` (string) – default often `us-central1`
* `repo_id` (string) – Artifact Registry repo name (e.g., `app`)
* `service_name` (string) – Cloud Run service name
* `image` (string) – fully qualified image URL; **CI sets this automatically**
* `app_envs` (map(string), optional) – environment variables for the container

### `*.tfvars` (how they work here)

* Local runs load values from your tfvars file, e.g. `terraform/vars/sandbox.tfvars`:

  ```hcl
  project_id   = "your-project-id"
  region       = "us-central1"
  repo_id      = "app"
  service_name = "fastapi-app"
  app_envs = {
    FOO = "bar"
  }
  ```

  Run:

  ```bash
  cd terraform
  ./trf sbx init
  ./trf sbx apply
  ```
* In **CI**, we pass variables via `TF_VAR_*` environment variables for just-in-time values:

  * `TF_VAR_project_id`, `TF_VAR_region` – static from repo secrets and workflow envs
  * `TF_VAR_image` – set by the build step to `${REGION}-docker.pkg.dev/PROJECT/REPO/SERVICE:${GITHUB_SHA}`

Terraform’s precedence rules mean **CLI/ENV values override tfvars**, so CI can safely inject the image tag while you keep defaults in tfvars for local use.

---

## CI/CD – how it works

**Trigger (automatic):**

* **Push to `main`** triggers the workflow in `.github/workflows/*.yaml`.

**Steps:**

1. **Auth via WIF**
   `google-github-actions/auth@v2` mints short-lived credentials using your WIF provider + deployer SA.
2. **Build image & push to Artifact Registry**
   Docker builds from `app/Dockerfile` and pushes to `${REGION}-docker.pkg.dev/<PROJECT>/<REPO_ID>/<SERVICE_NAME>:<SHA>`.
3. **Terraform apply**
   Runs from `terraform/`, passing the new `TF_VAR_image`, which updates Cloud Run to the latest image.
4. **Outputs**
   Terraform prints the Cloud Run URL when successful.

**Run it manually (two ways):**

* **Manual GitHub run**: add this to the workflow trigger:

  ```yaml
  on:
    push: { branches: [ "main" ] }
    workflow_dispatch: {}
  ```

  Then go to **Actions → the workflow → Run workflow**.
* **Local Terraform (no CI)**:

  ```bash
  docker build -t local/fastapi ./app
  docker run -p 8000:8000 local/fastapi  # quick smoke test
  cd terraform
  ./trf sbx init
  ./trf sbx apply -var="image=${REGION}-docker.pkg.dev/<PROJECT>/<REPO>/<SERVICE>:local"
  ```

---

## Repository Secrets (GitHub → Settings → Secrets and variables → Actions)

For **Direct WIF**:

* `GCP_PROJECT_ID`
* `GCP_WORKLOAD_IDENTITY_PROVIDER`
  *(and ensure your repo principal has needed roles directly)*

> Make sure no secret like `GOOGLE_CREDENTIALS` or `GCP_SA_KEY` is configured; this pipeline is **keyless**.

---
