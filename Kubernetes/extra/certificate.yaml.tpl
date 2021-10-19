apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${cert_name}
  namespace: ${namespace}
spec:
  dnsNames:
  - 'artifactory.${cluster_domain}'
  issuerRef:
    group: cert-manager.io
    kind: ClusterIssuer
    name: letsencrypt-prod
  secretName: ${cert_name}-tls
