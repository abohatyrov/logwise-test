locals {
  repo_principal = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# ============================= Workload Identity Permissions =============================

resource "google_project_iam_member" "repo_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = local.repo_principal
}

resource "google_project_iam_member" "repo_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = local.repo_principal
}

resource "google_storage_bucket_iam_member" "repo_tfstate_rw" {
  bucket = var.tfstate_bucket
  role   = "roles/storage.objectAdmin"
  member = local.repo_principal
}

# ============================= Service Account for Cloud Run =============================

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "${var.service_name}-runtime"
  display_name = "${var.service_name} runtime"
}

resource "google_service_account_iam_member" "repo_can_use_runtime_sa" {
  service_account_id = google_service_account.runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = local.repo_principal
}

# ============================= Cloud Run Permissions =============================

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
  depends_on = [google_cloud_run_v2_service.app]
}
