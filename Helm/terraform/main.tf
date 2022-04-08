resource "kubernetes_namespace" "app" {
  metadata {
    labels = {
      name = "app"
    }

    name = "app"
  }
}

resource "helm_release" "go_app" {
  name = "go-app"

  repository = "./templates/go-app"
  chart      = "go-app"
  version    = "0.1.0"
  namespace  = "app"

  values = [
    templatefile("${path.module}/templates/go-app/values.yaml.tpl", {
      ENV_ID     = data.vault_generic_secret.dynatrace.data["env_domain"],
      API_TOKEN  = data.vault_generic_secret.dynatrace.data["api_token"],
      PAAS_TOKEN = data.vault_generic_secret.dynatrace.data["paas_token"],
    })
  ]

  depends_on = [
    kubernetes_namespace.go_app
  ]
}
