#!/bin/bash


set -euo pipefail

INCLUDE_SERVICE=${INCLUDE_SERVICE:-"true"}
INCLUDE_DEPLOYMENT=${INCLUDE_DEPLOYMENT:-"true"}
SERVICE_VERSION=${SERVICE_VERSION:-"v1"}
while (( "$#" )); do
  case "$1" in
    --version)
      SERVICE_VERSION=$2
      shift 2
      ;;

    --includeService)
      INCLUDE_SERVICE=$2
      shift 2
      ;;

    --includeDeployment)
      INCLUDE_DEPLOYMENT=$2
      shift 2
      ;;

    *)
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
done

SERVICE_YAML=$(cat <<EOF
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  labels:
    app: helloworld
    service: helloworld
spec:
  ports:
  - port: 5000
    name: http
  selector:
    app: helloworld
EOF
)

DEPLOYMENT_YAML=$(cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-${SERVICE_VERSION}
  labels:
    app: helloworld
    version: ${SERVICE_VERSION}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helloworld
      version: ${SERVICE_VERSION}
  template:
    metadata:
      labels:
        app: helloworld
        version: ${SERVICE_VERSION}
    spec:
      containers:
      - name: helloworld
        env:
        - name: SERVICE_VERSION
          value: ${SERVICE_VERSION}
        image: docker.io/istio/examples-helloworld-v1
        resources:
          requests:
            cpu: "100m"
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
EOF
)

OUT=""

# Add the service to the output.
if [[ "$INCLUDE_SERVICE" == "true" ]]; then
  OUT="${SERVICE_YAML}"
fi

# Add the deployment to the output.
if [[ "$INCLUDE_DEPLOYMENT" == "true" ]]; then
  # Add a separator
  if [[ -n "$OUT" ]]; then
    OUT+="
---
"
  fi
  OUT+="${DEPLOYMENT_YAML}"
fi

echo "$OUT"
