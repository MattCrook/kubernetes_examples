# Example creating a namespace in Terraform (in this example, creating a namespace called "flagger")
# According to "best practices", better to create namespaces like this than manually or in yaml
resource "kubernetes_namespace" "flagger" {
  metadata {
    labels = {
      name = "flagger"
    }
    name = "flagger"
  }
}

# Example helm release in Terraform, deploying the flagger Helm chart to the flagger namespace created above.
# Flagger is a Kubernetes operator, and is s a progressive delivery tool that converts the release process for applications using Kubernetes to automatic operation.
# Flagger also shrinks the threat of a new software version in production by moving traffic to the new software version while measuring and running tests on metrics and conformance
# https://flagger.app/
# https://www.weave.works/oss/flagger/
resource "helm_release" "flagger" {
  name = "flagger"

  repository = "https://flagger.app"
  chart      = "flagger"
  version    = "1.14.0"
  namespace  = "flagger"

  set {
    name  = "meshProvider"
    value = "contour"
  }

  set {
    name  = "ingressClass"
    value = "contour"
  }

  set {
    name  = "metricsServer"
    value = "https://prometheus.gcp.development.website.com"
  }

  depends_on = [
    kubernetes_namespace.flagger,
  ]
}
