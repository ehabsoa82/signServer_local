# SignServer Community Helm Chart with SSL/TLS Support

This is a customized version of the SignServer Community Helm chart that adds support for HTTPS and client certificate authentication. It provides secure access to the SignServer admin interface through SSL/TLS and client certificates.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Features](#features-added)
3. [Directory Structure](#directory-structure)
4. [Certificate Generation](#certificate-generation)
   - [Server Certificate](#1-server-certificate)
   - [Client Certificate](#2-client-admin-certificate)
   - [Truststore](#3-truststore-configuration)
5. [Configuration](#key-configuration-changes-in-valuesyaml)
6. [Installation Steps](#installation-steps)
7. [Making Updates](#making-updates)
8. [Troubleshooting](#troubleshooting)
9. [Security Notes](#security-notes)

## Status Indicators
Throughout this document, you'll see these status indicators:
- 🟢 Ready/Success - Component is working correctly
- 🟡 Warning/Caution - Requires attention or special consideration
- 🔴 Error/Problem - Needs immediate attention
- ℹ️ Info - Additional information or tips
- 🔒 Security - Security-related information
- 🔧 Configuration - Configuration details

## Prerequisites

### Required Software 🔧
| Software | Version | Purpose |
|----------|---------|----------|
| Kubernetes | v1.19+ | Container orchestration platform |
| Helm | v3+ | Package manager for Kubernetes |
| kubectl | Latest | Kubernetes command-line tool |
| Java keytool | JDK 11+ | Certificate generation and management |
| OpenSSL | Latest | Certificate verification (optional) |

### System Requirements 🔧
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| Memory | 4GB RAM | 8GB RAM |
| Storage | 10GB | 20GB |

### Browser Requirements 🔧
One of the following browsers with client certificate support:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

### Knowledge Prerequisites ℹ️
Basic understanding of:
- Kubernetes concepts
- SSL/TLS certificates
- Helm charts
- Command line operations

## Features Added

- HTTPS support using self-signed certificates
- Client certificate authentication for admin interface
- Organized SSL certificate management
- Kubernetes secret management for certificates
- Port forwarding support for local development

## Directory Structure

```
.
├── Chart.yaml           # Helm chart metadata
├── values.yaml         # Customized configuration values
├── templates/          # Helm chart templates
│   ├── deployment.yaml
│   ├── services.yaml
│   ├── ingress.yaml
│   └── server-keystore-config.yaml  # Added for SSL support
├── config/
│   └── ssl/           # SSL certificates and configuration
│       ├── server/    # Server certificates
│       │   ├── server.jks
│       │   ├── server.pem
│       │   └── server.storepasswd
│       ├── client/    # Client certificates
│       │   ├── admin.jks
│       │   ├── admin.p12
│       │   └── admin.cer
│       └── truststore/ # Client certificate truststore
│           └── truststore.jks
└── create-keystore-secret.sh  # Script to create K8s secrets
```

## Certificate Generation

### 1. Server Certificate
```bash
cd config/ssl/server
keytool -genkeypair \
  -alias signserver \
  -keyalg RSA \
  -keysize 2048 \
  -validity 3650 \
  -keystore server.jks \
  -dname "CN=signserver,O=SignServer,C=SE" \
  -storepass changeit

# Export certificate for browser import
keytool -exportcert \
  -alias signserver \
  -keystore server.jks \
  -file server.pem \
  -rfc \
  -storepass changeit
```

### 2. Client (Admin) Certificate
```bash
cd config/ssl/client
keytool -genkeypair \
  -alias admin \
  -keyalg RSA \
  -keysize 2048 \
  -validity 3650 \
  -keystore admin.jks \
  -dname "CN=admin,O=SignServer,C=SE" \
  -storepass changeit

# Export certificate
keytool -exportcert \
  -alias admin \
  -keystore admin.jks \
  -file admin.cer \
  -storepass changeit

# Create PKCS12 for browser import
keytool -importkeystore \
  -srckeystore admin.jks \
  -destkeystore admin.p12 \
  -srcstoretype JKS \
  -deststoretype PKCS12 \
  -srcstorepass changeit \
  -deststorepass changeit \
  -srcalias admin \
  -destalias admin
```

### 3. Truststore Configuration
```bash
cd config/ssl/truststore
keytool -import \
  -alias admin \
  -file ../client/admin.cer \
  -keystore truststore.jks \
  -storepass signserver \
  -noprompt
```

## Key Configuration Changes in values.yaml 🔧

### Configuration Overview
The following table explains the key configuration changes made to `values.yaml`:

| Category | Setting | Value | Purpose |
|----------|---------|--------|---------|
| Database | useEphemeralH2Database | true | Use in-memory database |
| Database | useH2Persistence | false | No persistent storage |
| Security | importAppserverKeystore | true | Enable SSL keystore |
| Security | appserverKeystoreSecret | signserver-keystore | Store server certificate |
| Security | importAppserverTruststore | true | Enable client auth |
| Security | appserverTruststoreSecret | signserver-truststore | Store trusted certs |

### Environment Variables
| Variable | Value | Purpose |
|----------|-------|---------|
| SIGNSERVER_ADMIN_TLS_CLIENT_AUTH | true | Enable client cert auth |
| SIGNSERVER_ADMIN_TLS_CLIENT_CERT | true | Require client certs |
| SIGNSERVER_HEALTHCHECK_ENABLED | true | Enable health checks |
| SIGNSERVER_ADMIN_AUTHTYPE | CLIENTCERT | Use cert authentication |

### Paths and Passwords
| Setting | Value | Note |
|---------|-------|------|
| SIGNSERVER_ADMIN_TRUSTSTORE_PATH | /opt/keyfactor/signserver/conf/truststore.jks | 🔴 Don't change |
| SIGNSERVER_ADMIN_TRUSTSTORE_PASSWORD | signserver | 🔴 Change in prod |
| SIGNSERVER_KEYSTORE_PATH | /opt/keyfactor/secrets/external/tls/ks/server.jks | 🔴 Don't change |
| SIGNSERVER_KEYSTORE_PASSWORD | changeit | 🔴 Change in prod |

### Complete Configuration
```yaml
signserver:
  useEphemeralH2Database: true    # ℹ️ In-memory database
  useH2Persistence: false         # ℹ️ No persistence needed
  importAppserverKeystore: true   # 🔒 Required for SSL
  appserverKeystoreSecret: signserver-keystore  # 🔒 Server cert
  importAppserverTruststore: true  # 🔒 Required for client auth
  appserverTruststoreSecret: signserver-truststore  # 🔒 Client certs
  env:
    # Security Settings 🔒
    SIGNSERVER_ADMIN_TLS_CLIENT_AUTH: "true"   # Enable client auth
    SIGNSERVER_ADMIN_TLS_CLIENT_CERT: "true"   # Require client certs
    SIGNSERVER_HEALTHCHECK_ENABLED: "true"     # Health monitoring
    SIGNSERVER_ADMIN_AUTHTYPE: "CLIENTCERT"    # Auth mechanism
    
    # Paths and Credentials 🔐
    SIGNSERVER_ADMIN_TRUSTSTORE_PATH: /opt/keyfactor/signserver/conf/truststore.jks
    SIGNSERVER_ADMIN_TRUSTSTORE_PASSWORD: signserver  # 🔴 Change in prod
    SIGNSERVER_KEYSTORE_PATH: /opt/keyfactor/secrets/external/tls/ks/server.jks
    SIGNSERVER_KEYSTORE_PASSWORD: changeit  # 🔴 Change in prod
```

### Configuration Notes ℹ️
- All paths are container-internal paths
- Passwords should be changed in production
- Security settings are mandatory for HTTPS
- Database settings can be modified for persistence

## Installation Steps

### Quick Reference Guide 🔧
| Step | Command | Expected Result |
|------|---------|----------------|
| Clone repo | `git clone https://github.com/ehabsoa82/signServer_local.git` | Repository downloaded |
| Generate certs | Follow [Certificate Generation](#certificate-generation) | Certificates created |
| Create secrets | `./create-keystore-secret.sh` | Secrets created in K8s |
| Install chart | `helm upgrade --install signserver . -n signserver` | Chart deployed |
| Port forward | `kubectl port-forward ...` | Service accessible |
| Access UI | https://localhost:8443/signserver/adminweb/ | Admin UI loads |

### Detailed Installation Steps

1. Clone this repository and navigate to it:
```bash
# Download the repository
git clone https://github.com/ehabsoa82/signServer_local.git
cd signServer_local

# Verify you're in the correct directory
pwd  # Should show .../signServer_local
ls   # Should show Chart.yaml, values.yaml, etc.
```

2. Generate all required certificates (if not already done):
```bash
# Create directory structure
mkdir -p config/ssl/{server,client,truststore}

# Generate certificates following the steps in the Certificate Generation section
cd config/ssl
# ... (follow certificate generation steps above)
```

3. Create required secrets:
```bash
./create-keystore-secret.sh
```

4. Install/upgrade the Helm chart:
```bash
# Create namespace if it doesn't exist
kubectl create namespace signserver

# Install/upgrade the chart
helm upgrade --install signserver . -n signserver
```

5. Wait for the pod to be ready:
```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=signserver -n signserver --timeout=300s
```

6. Set up port forwarding:
```bash
# Run in background
nohup kubectl port-forward -n signserver svc/signserver-signserver-community-helm 8443:8443 > port-forward.log 2>&1 &

# Verify port forwarding is active
ps aux | grep "port-forward" | grep "signserver"
```

7. Configure browser:
   - Import server.pem as a trusted certificate authority:
     * Chrome: Settings → Privacy and Security → Security → Manage Certificates → Authorities → Import
     * Firefox: Preferences → Privacy & Security → View Certificates → Authorities → Import
   - Import admin.p12 as a client certificate (password: changeit):
     * Chrome: Settings → Privacy and Security → Security → Manage Certificates → Your Certificates → Import
     * Firefox: Preferences → Privacy & Security → View Certificates → Your Certificates → Import
   - Add to hosts file:
     ```bash
     # Add this line to /etc/hosts (requires sudo)
     127.0.0.1 signserver.local
     ```

8. Access admin interface:
   - URL: https://localhost:8443/signserver/adminweb/
   - When prompted, select the admin certificate
   - Verify that you see the admin interface without certificate errors

9. Verify the installation:
```bash
# Check pod status
kubectl get pods -n signserver

# Check logs for any errors
kubectl logs -n signserver -l app.kubernetes.io/name=signserver

# Test HTTPS connection
curl -k -v https://localhost:8443/signserver/adminweb/
```

## Making Updates

### 1. Certificate Updates
When certificates expire or need to be renewed:
1. Generate new certificates following the steps above
2. Update the secrets:
```bash
./create-keystore-secret.sh
```
3. Restart the pods:
```bash
kubectl rollout restart deployment -n signserver signserver-signserver-community-helm
```

### 2. Configuration Changes
To modify SignServer configuration:
1. Update values.yaml with new settings
2. Upgrade the deployment:
```bash
helm upgrade signserver . -n signserver
```

### 3. Code Changes
To make changes to the Helm chart:
1. Make your changes
2. Commit and push:
```bash
git add .
git commit -m "Description of changes"
git push
```

## Troubleshooting

### Certificate Issues

1. Check certificate validity and expiration:
```bash
# Check client certificate
keytool -list -v -keystore config/ssl/client/admin.p12 -storepass changeit

# Check server certificate
keytool -list -v -keystore config/ssl/server/server.jks -storepass changeit

# Verify certificate chain
openssl verify -CAfile config/ssl/server/server.pem config/ssl/client/admin.cer
```

2. Verify truststore content and configuration:
```bash
# List trusted certificates
keytool -list -v -keystore config/ssl/truststore/truststore.jks -storepass signserver

# Verify certificate is in truststore
keytool -list -v -keystore config/ssl/truststore/truststore.jks -storepass signserver | grep "admin"
```

3. Common certificate problems:
   - Certificate not yet valid or expired
   - Wrong certificate format
   - Missing certificate chain
   - Incorrect password
   - Wrong certificate purpose (e.g., server cert as client cert)

### Connection Issues

1. Check pod and service status:
```bash
# Check pod status
kubectl get pods -n signserver

# Check service status
kubectl get svc -n signserver

# Check pod logs
kubectl logs -n signserver -l app.kubernetes.io/name=signserver
```

2. Verify port forwarding:
```bash
# List port forwarding processes
ps aux | grep "port-forward"

# Test connection
curl -k -v https://localhost:8443/signserver/adminweb/

# Check if port is listening
lsof -i :8443
```

3. Test SSL/TLS connection:
```bash
# Test with client certificate
curl -k -v --cert config/ssl/client/admin.p12:changeit \
  https://localhost:8443/signserver/adminweb/

# Check server certificate
openssl s_client -connect localhost:8443 -servername signserver.local
```

### Configuration Issues

1. Check secret creation:
```bash
# List secrets
kubectl get secrets -n signserver

# Describe secrets
kubectl describe secret signserver-keystore -n signserver
kubectl describe secret signserver-truststore -n signserver
```

2. Verify environment variables:
```bash
# Get pod name
POD=$(kubectl get pod -n signserver -l app.kubernetes.io/name=signserver -o jsonpath='{.items[0].metadata.name}')

# Check environment variables
kubectl exec -n signserver $POD -- env | grep SIGNSERVER
```

3. Check mounted volumes:
```bash
# Verify volume mounts
kubectl describe pod -n signserver $POD

# Check mounted files
kubectl exec -n signserver $POD -- ls -l /opt/keyfactor/secrets/external/tls/ks/
kubectl exec -n signserver $POD -- ls -l /opt/keyfactor/signserver/conf/
```

### Browser Issues

1. Chrome:
   - Open chrome://settings/certificates
   - Verify both server and client certificates are properly imported
   - Check certificate trust settings

2. Firefox:
   - Open about:preferences#privacy
   - Check Security → Certificates
   - Verify certificate trust settings

3. Common browser problems:
   - Certificate not imported correctly
   - Wrong certificate store (personal vs authority)
   - Browser not configured to send client certificates
   - Certificate trust settings incorrect

## Security Notes 🔒

### Development vs Production 
| Aspect | Development | Production |
|--------|-------------|------------|
| Certificates | Self-signed OK | Must use CA-signed |
| Passwords | Default OK | Must be strong, unique |
| Storage | Local files OK | Must use K8s secrets |
| Access | Local access OK | Must use proper RBAC |

### Security Checklist
- [ ] Use CA-signed certificates in production
- [ ] Configure strong passwords
- [ ] Enable audit logging
- [ ] Set up monitoring
- [ ] Configure RBAC
- [ ] Secure network policies
- [ ] Regular certificate rotation
- [ ] Backup management

### Best Practices
1. Certificate Management
   - Rotate certificates every 90 days
   - Use minimum 2048-bit RSA keys
   - Keep private keys secured

2. Access Control
   - Use role-based access control (RBAC)
   - Implement network policies
   - Enable audit logging

3. Monitoring
   - Monitor certificate expiration
   - Track failed login attempts
   - Set up alerts for security events

### Security Contacts
- Report security issues: security@your-org.com
- Emergency contact: +1-XXX-XXX-XXXX

🔴 **WARNING**: The default certificates and passwords in this repository are for development only. 
Never use them in a production environment!

There are two versions of SignServer:

* **SignServer Community** (SignServer CE) - free and open source, OSI Certified Open Source Software, LGPL-licensed subset of SignServer Enterprise
* **SignServer Enterprise** (SignServer EE) - developed and commercially supported

OSI Certified is a certification mark of the Open Source Initiative.

## Community Support

In our Community we welcome contributions. The Community software is open source and community supported, there is no support SLA, but a helpful best-effort Community.

* To report a problem or suggest a new feature, use the **[Issues](../../issues)** tab.
* If you want to contribute actual bug fixes or proposed enhancements, use the **[Pull requests](../../pulls)** tab.
* Ask the community for ideas: **[SignServer Discussions](https://github.com/Keyfactor/signserver-ce/discussions)**.
* Read more in our documentation: **[SignServer Documentation](https://doc.primekey.com/signserver)**.
* See release information: **[SignServer Release information](https://doc.primekey.com/signserver/signserver-release-information)**.
* Read more on the open source project website: **[SignServer website](https://www.signserver.org/)**.

## Commercial Support
Commercial support is available for **[SignServer Enterprise](https://www.keyfactor.com/platform/keyfactor-signserver-enterprise/)**.

## License
SignServer Community is licensed under the LGPL license, please see **[LICENSE](LICENSE)**.


## Prerequisites

- [Kubernetes](http://kubernetes.io) v1.19+
- [Helm](https://helm.sh) v3+
- [EJBCA](https://www.ejbca.org), or another certificate authority for infrastructure and signer certificates.  

## Getting started

The **SignServer Community Helm Chart** bootstraps **SignServer Community** on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

SignServer depends on an existing PKI for infrastructure certificates (client TLS for administration and optionally server TLS) as well as for signer certificates for workers. [EJBCA](https://www.ejbca.org) is an open-source, enterprise-grade, PKI software that is [easy to get started](https://www.ejbca.org/use-cases/get-started-with-ejbca-pki/) with and [can be deployed in Kubernetes using Helm](https://github.com/Keyfactor/ejbca-community-helm).

### Add repo
```shell
helm repo add keyfactor https://keyfactor.github.io/ejbca-community-helm/
```

### Quick start

Deploying `signserver-community-helm` using default configurations will start SignServer with an ephemeral database and without the possibility of accessing the administration web interface. In order to be able to use SignServer, you should customize the deployment to allow admin web access and/or use pre-configured worker properties files.

### Custom deployment

To customize the installation, create and edit a custom values file with deployment parameters:
```shell
helm show values keyfactor/signserver-community-helm > signserver.yaml
```
Deploy `signserver-community-helm` on the Kubernetes cluster with custom configurations:
```shell
helm install signserver keyfactor/signserver-community-helm --namespace signserver --create-namespace --values signserver.yaml
```

## Example Custom Deployments

This section contains examples of how to customize the deployment for common scenarios.

## Connecting SignServer to an external database

All serious deployments of SignServer should use an external database for data persistence.
SignServer supports Microsoft SQL Server, MariaDB/MySQL, PostgreSQL, and Oracle databases. 

The following example shows modifications to the helm chart values file used to connect SignServer to a MariaDB database with server name `mariadb-server` and database name `signserverdb` using username `signserver` and password `foo123`:

```yaml
signserver:
  useEphemeralH2Database: false
  env:
    DATABASE_JDBC_URL: jdbc:mariadb://mariadb-server:3306/signserverdb?characterEncoding=UTF-8
    DATABASE_USER: signserver
    DATABASE_PASSWORD: foo123
```

This example connects SignServer to a PostgreSQL database and uses a Kubernetes secret for storing the database username and password:

```yaml
signserver:
  useEphemeralH2Database: false
  env:
    DATABASE_JDBC_URL: jdbc:postgresql://postgresql-server:5432/signserverdb
  envRaw:
    - name: DATABASE_PASSWORD
      valueFrom:
       secretKeyRef:
         name: signserver-db-credentials
         key: database_password
    - name: DATABASE_USER
      valueFrom:
       secretKeyRef:
         name: signserver-db-credentials
         key: database_user
```

Helm charts can be used to deploy a database in Kubernetes, for example the following by Bitnami:

- https://artifacthub.io/packages/helm/bitnami/postgresql
- https://artifacthub.io/packages/helm/bitnami/mariadb


### Configuring TLS termination in container for administrator access

The SignServer container can be provided with a custom keystore and truststore for TLS termination directly in the container. 

Create Kubernetes secrets using the following commands:

```shell
kubectl create secret generic keystore-secret --from-file=server.jks=server.jks --from-file=server.storepasswd=server.storepasswd

kubectl create secret generic truststore-secret --from-file=truststore.jks=ManagementCA-chain.jks --from-file=truststore.storepasswd=truststore.storepasswd
```

*server.jks* is the server keystore in JKS format, *server.storepasswd* is a text file containing the password to *server.jks*.

*truststore.jks* is the mTLS truststore and should contain certificate(s) of trusted CA(s) that issue administrator client TLS certificates.

Configure the helm chart to import keystore and truststore from the created secrets:

```yaml
signserver:
  importAppserverKeystore: true
  appserverKeystoreSecret: keystore-secret
  importAppserverTruststore: true
  appserverTruststoreSecret: truststore-secret
```

### Configuring SignServer to sit behind a reverse proxy 

It is best practice to place SignServer behind a reverse proxy server that handles TLS termination and/or load balancing.

The following example shows how to configure a deployment to expose an AJP proxy port as a ClusterIP service:

```yaml
services:
  directHttp:
    enabled: false
  proxyAJP:
    enabled: true
    type: ClusterIP
    bindIP: 0.0.0.0
    port: 8009
  proxyHttp:
    enabled: false
```

This example exposes two proxy HTTP ports, where port 8082 will accept the SSL_CLIENT_CERT HTTP header to enable mTLS:

```yaml
services:
  directHttp:
    enabled: false
  proxyAJP:
    enabled: false
  proxyHttp:
    enabled: true
    type: ClusterIP
    bindIP: 0.0.0.0
    httpPort: 8081
    httpsPort: 8082
```

### Enabling Ingress in front of SignServer

Ingress is a Kubernetes native way of exposing HTTP and HTTPS routes from outside to Kubernetes services.

The following example shows how Ingress can be enabled with this helm chart using proxy AJP. 
Note that a TLS secret containing `tls.crt` and `tls.key` with certificate and private key would need to be prepared in advance and that *nginx.ingress.kubernetes.io/auth-tls-secret* must reference a secret containing a file named `ca.crt` with CA certificates that allow authentication.

```yaml
services:
  directHttp:
    enabled: false
  proxyAJP:
    enabled: true
    type: ClusterIP
    bindIP: 0.0.0.0
    port: 8009
  proxyHttp:
    enabled: false

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
    nginx.ingress.kubernetes.io/auth-tls-secret: "default/managementca-secret"
    nginx.ingress.kubernetes.io/auth-tls-pass-certificate-to-upstream: "true"
  hosts:
    - host: "signserver.minikube.local"
      paths:
        - path: /signserver
          pathType: Prefix
  tls:
    - hosts:
        - signserver.minikube.local
      secretName: ingress-tls
```

### Importing signer keystores into SignServer container

Keystore files containing signer keys and certificates that should be used by SignServer workers can be imported from a Kubernetes secret.

Use the following command to create a secret containing one or more keystore files:

```shell
kubectl create secret generic signer-keystores-secret --from-file=signer_keystore.p12=signer_keystore.p12
```

Configure the chart to mount keystore files from the secret. `keystoresMountPath` is where the files should be placed in the container:

```yaml
signserver:
  importKeystores: true
  keystoresSecret: signer-keystores-secret
  keystoresMountPath: /mnt/external
```

### Configuring SignServer using worker properties files

SignServer can be fully configured using properties files. 

The example below configures two workers, a crypto worker that connects to keystore files located at `/mnt/external/signer_keystore.p12` and a PlainSigner that signs using the key signKey0001 from this keystore:

```
WORKER1.NAME=SignerCryptoToken
WORKER1.TYPE=CRYPTO_WORKER
WORKER1.IMPLEMENTATION_CLASS=org.signserver.server.signers.CryptoWorker
WORKER1.CRYPTOTOKEN_IMPLEMENTATION_CLASS=org.signserver.server.cryptotokens.KeystoreCryptoToken
WORKER1.KEYSTORETYPE=PKCS12
WORKER1.KEYSTOREPATH=/mnt/external/signer_keystore.p12
WORKER1.KEYSTOREPASSWORD=foo123
WORKER1.DEFAULTKEY=testKey

WORKER2.NAME=PlainSigner
WORKER2.TYPE=PROCESSABLE
WORKER2.IMPLEMENTATION_CLASS=org.signserver.module.cmssigner.PlainSigner
WORKER2.CRYPTOTOKEN=SignerCryptoToken
WORKER2.DEFAULTKEY=signKey0001
WORKER2.DISABLEKEYUSAGECOUNTER=true
WORKER2.AUTHTYPE=NOAUTH
```

Create a secret from one or more text files with worker properties:

```shell
kubectl create secret generic workers-secret --from-file=workers.properties=workers.properties
```

Configure the chart to import worker properties at start-up:

```yaml
signserver:
  importWorkerProperties: true
  workerPropertiesSecret: workers-secret
```

Sample properties files for different types of workers are available in the [SignServer GitHub repository](https://github.com/Keyfactor/signserver-ce/tree/main/signserver/doc/sample-configs).

Note that the samples prefix properties with `WORKERGENID1` which always creates a new worker. In order to handle container restarts, exact worker ID should be used like in the example above. This way the worker is created if it does not already exist, otherwise properties are applied to the existing worker with that ID.

## Parameters

### SignServer Deployment Parameters

| Name                                  | Description                                                                                            | Default |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------- |
| signserver.useEphemeralH2Database     | If in-memory internal H2 database should be used                                                       | true    |
| signserver.useH2Persistence           | If internal H2 database with persistence should be used. Requires existingH2PersistenceClaim to be set | false   |
| signserver.existingH2PersistenceClaim | PersistentVolumeClaim that internal H2 database can use for data persistence                           |         |
| signserver.importAppserverKeystore    | If an existing keystore should be used for TLS configurations when reverse proxy is not used           | false   |
| signserver.appserverKeystoreSecret    | Secret containing keystore for TLS configuration of SignServer application server                      |         |
| signserver.importAppserverTruststore  | If an existing truststore should be used for TLS configurations when reverse proxy is not used         | false   |
| signserver.appserverTruststoreSecret  | Secret containing truststore for TLS configuration of SignServer application server                    |         |
| signserver.importWorkerProperties     | If properties files should be used to configure SignServer                                             | false   |
| signserver.workerPropertiesSecret     | Secret containing properties files used for configuring SignServer at startup                          |         |
| signserver.importKeystores            | If keystore files should be mounted into the SignServer container                                      | false   |
| signserver.keystoresSecret            | Secret containing keystore files that can be used by SignServer workers                                |         |
| signserver.keystoresMountPath         | Mount path in the SignServer container for mounted keystore files                                      |         |
| signserver.env                        | Environment variables to pass to container                                                             |         |
| signserver.envRaw                     | Environment variables to pass to container in Kubernetes YAML format                                   |         |
| signserver.initContainers             | Extra init containers to be added to the deployment                                                    | []      |
| signserver.sidecarContainers          | Extra sidecar containers to be added to the deployment                                                 | []      |
| signserver.volumes                    | Extra volumes to be added to the deployment                                                            | []      |
| signserver.volumeMounts               | Extra volume mounts to be added to the deployment                                                      | []      |

### SignServer Environment Variables

| Name                                         | Description                                                                                                                                                                                                | Default |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| signserver.env.DATABASE_JDBC_URL             | JDBC URL to external database                                                                                                                                                                              |         |
| signserver.env.DATABASE_USER                 | The username part of the credentials to access the external database                                                                                                                                       |         |
| signserver.env.DATABASE_PASSWORD             | The password part of the credentials to access the external database                                                                                                                                       |         |
| signserver.env.DATABASE_USER_PRIVILEGED      | The username part of the credentials to access the external database if separate account is used for creating tables and schema changes                                                                    |         |
| signserver.env.DATABASE_PASSWORD_PRIVILEGED  | The password part of the credentials to access the external database if separate account is used for creating tables and schema changes                                                                    |         |
| signserver.env.LOG_LEVEL_APP                 | Application log level                                                                                                                                                                                      |         |
| signserver.env.LOG_LEVEL_APP_WS_TRANSACTIONS | Application log level for WS transaction logging                                                                                                                                                           |         |
| signserver.env.LOG_LEVEL_SERVER              | Application server log level for main system                                                                                                                                                               |         |
| signserver.env.LOG_LEVEL_SERVER_SUBSYSTEMS   | Application server log level for sub-systems                                                                                                                                                               |         |
| signserver.env.LOG_STORAGE_LOCATION          | Path in the Container (directory) where the log will be saved, so it can be mounted to a host directory. The mounted location must be a writable directory                                                 |         |
| signserver.env.LOG_STORAGE_MAX_SIZE_MB       | Maximum total size of log files (in MB) before being discarded during log rotation. Minimum requirement: 2 (MB)                                                                                            |         |
| signserver.env.LOG_AUDIT_TO_DB               | Set this value to true if the internal SignServer audit log is needed                                                                                                                                      |         |
| signserver.env.TZ                            | TimeZone to use in the container                                                                                                                                                                           |         |
| signserver.env.APPSERVER_DEPLOYMENT_TIMEOUT  | This value controls the deployment timeout in seconds for the application server when starting the application                                                                                             |         |
| signserver.env.JAVA_OPTS_CUSTOM              | Allows you to override the default JAVA_OPTS that are set in the standalone.conf                                                                                                                           |         |
| signserver.env.PROXY_AJP_BIND                | Run container with an AJP proxy port :8009 bound to the IP address in this variable, e.g. PROXY_AJP_BIND=0.0.0.0                                                                                           |         |
| signserver.env.PROXY_HTTP_BIND               | Run container with two HTTP back-end proxy ports :8081 and :8082 configured bound to the IP address in this variable. Port 8082 will accepts the SSL_CLIENT_CERT HTTP header, e.g. PROXY_HTTP_BIND=0.0.0.0 |         |

### Services Parameters

| Name                          | Description                                                                                               | Default   |
| ----------------------------- | --------------------------------------------------------------------------------------------------------- | --------- |
| services.directHttp.enabled   | If service for communicating directly with SignServer container should be enabled                          | true      |
| services.directHttp.type      | Service type for communicating directly with SignServer container                                          | NodePort  |
| services.directHttp.httpPort  | HTTP port for communicating directly with SignServer container                                             | 31080     |
| services.directHttp.httpsPort | HTTPS port for communicating directly with SignServer container                                            | 31443     |
| services.proxyAJP.enabled     | If service for reverse proxy servers to communicate with SignServer container over AJP should be enabled  | false     |
| services.proxyAJP.type        | Service type for proxy AJP communication                                                                  | ClusterIP |
| services.proxyAJP.bindIP      | IP to bind for proxy AJP communication                                                                    | 0.0.0.0   |
| services.proxyAJP.port        | Service port for proxy AJP communication                                                                  | 8009      |
| services.proxyHttp.enabled    | If service for reverse proxy servers to communicate with SignServer container over HTTP should be enabled | false     |
| services.proxyHttp.type       | Service type for proxy HTTP communication                                                                 | ClusterIP |
| services.proxyHttp.bindIP     | IP to bind for proxy HTTP communication                                                                   | 0.0.0.0   |
| services.proxyHttp.httpPort   | Service port for proxy HTTP communication                                                                 | 8081      |
| services.proxyHttp.httpsPort  | Service port for proxy HTTP communication that accepts SSL_CLIENT_CERT header                             | 8082      |
| services.sidecarPorts         | Additional ports to expose in sidecar containers                                                          | []        |


### Ingress Parameters

| Name                | Description                                 | Default           |
| ------------------- | ------------------------------------------- | ----------------- |
| ingress.enabled     | If ingress should be created for SignServer | false             |
| ingress.className   | Ingress class name                          | "nginx"           |
| ingress.annotations | Ingress annotations                         | <see values.yaml> |
| ingress.hosts       | Ingress hosts configurations                | []                |
| ingress.tls         | Ingress TLS configurations                  | []                |

### Deployment Parameters

| Name                                          | Description                                                                                                            | Default                 |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| replicaCount                                  | Number of SignServer replicas                                                                                          | 1                       |
| image.repository                              | SignServer image repository                                                                                            | keyfactor/signserver-ce |
| image.pullPolicy                              | SignServer image pull policy                                                                                           | IfNotPresent            |
| image.tag                                     | Overrides the image tag whose default is the chart appVersion                                                          |                         |
| imagePullSecrets                              | SignServer image pull secrets                                                                                          | []                      |
| nameOverride                                  | Overrides the chart name                                                                                               | ""                      |
| fullnameOverride                              | Fully overrides generated name                                                                                         | ""                      |
| serviceAccount.create                         | Specifies whether a service account should be created                                                                  | true                    |
| serviceAccount.annotations                    | Annotations to add to the service account                                                                              | {}                      |
| serviceAccount.name                           | The name of the service account to use. If not set and create is true, a name is generated using the fullname template | ""                      |
| podAnnotations                                | Additional pod annotations                                                                                             | {}                      |
| podSecurityContext                            | Pod security context                                                                                                   | {}                      |
| securityContext                               | Container security context                                                                                             | {}                      |
| resources                                     | Resource requests and limits                                                                                           | {}                      |
| autoscaling.enabled                           | If autoscaling should be used                                                                                          | false                   |
| autoscaling.minReplicas                       | Minimum number of replicas for autoscaling deployment                                                                  | 1                       |
| autoscaling.maxReplicas                       | Maximimum number of replicas for autoscaling deployment                                                                 | 5                       |
| autoscaling.targetCPUUtilizationPercentage    | Target CPU utilization for autoscaling deployment                                                                      | 80                      |
| autoscaling.targetMemoryUtilizationPercentage | Target memory utilization for autoscaling deployment                                                                   |                         |
| nodeSelector                                  | Node labels for pod assignment                                                                                         | {}                      |
| tolerations                                   | Tolerations for pod assignment                                                                                         | []                      |
| affinity                                      | Affinity for pod assignment                                                                                            | {}                      |
