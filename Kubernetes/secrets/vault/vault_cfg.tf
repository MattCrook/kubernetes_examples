data "vault_generic_secret" "bootstrap" {
  path = "terraform/bootstrap"
}

resource "kubernetes_service_account" "concourse_helm_client" {
  metadata {
    name      = "concourse-helm-client"
    namespace = "pipeline"
  }

  depends_on = [
    kubernetes_namespace.pipeline,
  ]
}

resource "kubernetes_cluster_role" "concourse_helm_client" {
  metadata {
    name = "concourse-helm"
    annotations = {
      name  = "rbac.authorization.kubernetes.io/autoupdate"
      value = "true"
    }

  }

  rule {
    api_groups = ["", "extensions", "apps", "rbac.authorization.k8s.io", "batch", "policy", "keda.sh", "discovery.k8s.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["projectcontour.io"]
    resources  = ["httpproxies", "tlscertificatedelegations"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  depends_on = [
    kubernetes_service_account.concourse_helm_client,
  ]
}

resource "kubernetes_cluster_role_binding" "concourse_helm_client_binding" {
  metadata {
    name = "concourse-helm-client-binding"
    annotations = {
      name  = "rbac.authorization.kubernetes.io/autoupdate"
      value = "true"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.concourse_helm_client.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.concourse_helm_client.metadata[0].name
    namespace = "pipeline"
  }
}

resource "kubernetes_service_account" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = "pipeline"
  }

  depends_on = [
    kubernetes_namespace.pipeline,
  ]
}

resource "kubernetes_cluster_role_binding" "tokenreview_cluster_role_binding" {
  metadata {
    name = "role-tokenreview-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault_auth.metadata[0].name
    namespace = "pipeline"
  }
}

resource "kubernetes_config_map" "configmap_vault" {
  metadata {
    name      = "vault"
    namespace = var.cluster_group
  }

  data = {
    "VAULT_ADDR"       = data.vault_generic_secret.bootstrap.data["vault_addr"]
    "VAULT_MOUNT_PATH" = local.short_cluster_name
  }

  depends_on = [
    kubernetes_namespace.pipeline,
  ]
}

data "kubernetes_secret" "vault_auth" {
  metadata {
    name      = kubernetes_service_account.vault_auth.default_secret_name
    namespace = "pipeline"
  }
}

data "kubernetes_service_account" "default" {
  metadata {
    name      = "default"
    namespace = "default"
  }
}

data "kubernetes_secret" "default" {
  metadata {
    name      = data.kubernetes_service_account.default.default_secret_name
    namespace = "default"
  }
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = local.short_cluster_name
}

resource "vault_kubernetes_auth_backend_config" "backend" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://${data.google_container_cluster.gke.endpoint}"
  kubernetes_ca_cert = data.kubernetes_secret.default.data["ca.crt"]
  token_reviewer_jwt = data.kubernetes_secret.vault_auth.data["token"]
}

data "kubernetes_secret" "concourse_sa_token" {
  metadata {
    name      = kubernetes_service_account.concourse_helm_client.default_secret_name
    namespace = "pipeline"
  }
}

resource "vault_generic_secret" "concourse_sa_token" {
  path = "concourse/${var.cluster_group}/${var.region}-concourse-sa-token"

  data_json = <<EOT
{
  "value": "${data.kubernetes_secret.concourse_sa_token.data["token"]}"
}
EOT
}

resource "vault_generic_secret" "ingress_domain" {
  count = var.enable_cert_manager && var.enable_contour ? 1 : 0
  path  = "concourse/${var.cluster_group}/${var.region}-ingress-domain"

  data_json = <<EOT
{
  "value": "${var.cluster_domain}"
}
EOT
}

resource "vault_generic_secret" "ingress_tls_secret" {
  count = var.enable_cert_manager && var.enable_contour ? 1 : 0
  path  = "concourse/${var.cluster_group}/${var.region}-ingress-tls-secret"

  data_json = <<EOT
{
  "value": "prod-wildcard-${replace(var.cluster_domain, ".", "-")}-tls"
}
EOT
}

resource "vault_generic_secret" "cluster_url" {
  path = "concourse/${var.cluster_group}/${var.region}-k8s-cluster-url"

  data_json = <<EOT
{
  "value": "https://${data.google_container_cluster.gke.endpoint}"
}
EOT
}

resource "vault_generic_secret" "cluster_ca" {
  path = "concourse/${var.cluster_group}/${var.region}-k8s-cluster-ca"

  data_json = <<EOT
{
  "value": "${base64encode(data.kubernetes_secret.concourse_sa_token.data["ca.crt"])}"
}
EOT
}
