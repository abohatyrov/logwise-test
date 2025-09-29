resource "google_cloud_run_v2_service" "app" {
  name     = var.service_name
  project  = var.project_id
  location = var.region

  template {
    service_account = google_service_account.runtime.email

    containers {
      image = var.image != "" ? var.image : "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_id}/${var.service_name}:latest"
      
      ports {
        container_port = 8000
      }

      dynamic "env" {
        for_each = var.app_envs
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_artifact_registry_repository.docker,
    google_service_account.runtime,
    google_project_iam_member.repo_run_admin,
    google_project_iam_member.repo_ar_writer,
    google_service_account_iam_member.repo_can_use_runtime_sa
  ]
}
