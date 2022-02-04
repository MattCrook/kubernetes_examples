output "ca_certificate" {
  description = "Public certificate of the cluster (base64-encoded)."
  value       = google_container_cluster.cluster.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "cluster" {
  description = "Cluster resource."
  sensitive   = true
  value       = google_container_cluster.cluster
}

output "endpoint" {
  description = "Cluster endpoint."
  value       = google_container_cluster.cluster.endpoint
}

output "location" {
  description = "Cluster location."
  value       = google_container_cluster.cluster.location
}

output "master_version" {
  description = "Master version."
  value       = google_container_cluster.cluster.master_version
}

output "name" {
  description = "Cluster name."
  value       = google_container_cluster.cluster.name
}

output "notifications" {
  description = "GKE PubSub notifications topic."
  value       = var.notification_config ? google_pubsub_topic.notifications[0].id : null
}
