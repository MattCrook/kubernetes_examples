output "name" {
  description = "Nodepool name."
  value       = google_container_node_pool.nodepool.name
}

output "service_account" {
  description = "Service account resource."
  value = (
    var.node_service_account_create
    ? google_service_account.service_account[0]
    : null
  )
}

output "service_account_email" {
  description = "Service account email."
  value       = local.service_account_email
}

output "service_account_iam_email" {
  description = "Service account email."
  value = join("", [
    "serviceAccount:",
    local.service_account_email == null ? "" : local.service_account_email
  ])
}
