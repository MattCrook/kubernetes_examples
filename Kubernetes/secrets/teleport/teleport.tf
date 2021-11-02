data "vault_generic_secret" "teleport" {
  path = "terraform/teleport-kube-agent"
}

resource "kubernetes_namespace" "teleport" {
  metadata {
    labels = {
      name = "teleport"
    }
    name = "teleport"
  }
}

resource "helm_release" "teleport-kube-agent" {
  name = "teleport"

  repository = "https://charts.releases.teleport.dev"
  chart      = "teleport-kube-agent"
  version    = "6"
  namespace  = kubernetes_namespace.teleport.metadata[0].name

  set_sensitive {
    name  = "authToken"
    value = data.vault_generic_secret.teleport.data["authToken"]
  }

  set {
    name  = "replicaCount"
    value = "3"
  }

  set {
    name  = "proxyAddr"
    value = data.vault_generic_secret.teleport.data["proxy_host"]
  }

  set {
    name  = "kubeClusterName"
    value = var.cluster_name
  }

  depends_on = [
    kubernetes_namespace.teleport
  ]
}
