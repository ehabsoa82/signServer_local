#!/bin/bash
set -e

NAMESPACE="signserver"
SSL_DIR="config/ssl"

# Check if namespace exists, create if it doesn't
if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
  echo "Creating namespace $NAMESPACE"
  kubectl create namespace $NAMESPACE
fi

# Create or update server keystore secret
echo "Creating/updating server keystore secret..."
kubectl create secret generic signserver-keystore \
  --from-file=server.jks=${SSL_DIR}/server/server.jks \
  --from-file=server.storepasswd=${SSL_DIR}/server/server.storepasswd \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

# Create or update truststore secret
echo "Creating/updating truststore secret..."
kubectl create secret generic signserver-truststore \
  --from-file=truststore.jks=${SSL_DIR}/truststore/truststore.jks \
  --from-file=truststore.storepasswd=<(echo -n "signserver") \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets created/updated successfully"