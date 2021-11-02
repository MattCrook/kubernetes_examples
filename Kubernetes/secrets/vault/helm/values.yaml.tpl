injector:
  enabled: true
  replicas: 3
  externalVaultAddr: ${vault_addr}
  authPath: "auth/${vault_path}"
  port: 8443
  priorityClassName: vault-injector
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app.kubernetes.io/name: {{ template "vault.name" . }}-agent-injector
              app.kubernetes.io/instance: "{{ .Release.Name }}"
              component: webhook
          topologyKey: kubernetes.io/hostname
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values:
            - us-central1-a
            - us-central1-b
            - us-central1-c
            - us-central1-f
            - us-east4-a
            - us-east4-b
            - us-east4-c
            - us-east4-f

server:
  serviceAccount:
    create: false
    name: ${vault_sa}
