resource "kubernetes_namespace" "vault" {
  count = var.enable_vault_injector ? 1 : 0
  metadata {
    labels = {
      name = "vault"
    }
    name = "vault"
  }
}

resource "kubernetes_priority_class" "vault" {
  metadata {
    name = "vault-injector"
  }

  value = 10
}

resource "helm_release" "vault" {
  count = var.enable_vault_injector ? 1 : 0
  name  = "vault"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.16.0"
  namespace  = "vault"

  values = [
    templatefile("${path.module}/helm/vault/values.yaml.tpl", {
      vault_path = vault_auth_backend.kubernetes.path,
      vault_addr = data.vault_generic_secret.bootstrap.data["vault_addr"],
      vault_sa   = kubernetes_service_account.vault_auth.metadata[0].name
    })
  ]

  depends_on = [
    kubernetes_namespace.vault,
    kubernetes_priority_class.vault,
    kubernetes_service_account.concourse_helm_client,
    vault_auth_backend.kubernetes,
    vault_kubernetes_auth_backend_config.backend,
  ]
}

resource "kubernetes_pod_disruption_budget" "vault-injector" {
  count = var.enable_vault_injector ? 1 : 0
  metadata {
    name      = "vault-injector"
    namespace = "vault"
  }
  spec {
    max_unavailable = "1"
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "vault-agent-injector",
        "app.kubernetes.io/instance" = "vault-injector",
        "component"                  = "webhook"
      }
    }
  }
  depends_on = [
    helm_release.vault
  ]
}
