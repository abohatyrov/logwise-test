output "cloud_run_url" {
  value = google_cloud_run_v2_service.app.uri
}

output "wif_provider_resource_name" {
  value = google_iam_workload_identity_pool_provider.github.name
}