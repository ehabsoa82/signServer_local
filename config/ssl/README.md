# SSL Configuration

This directory contains SSL certificates for SignServer:

## Directory Structure

- `server/`: Server certificates and keys
  - `server.jks`: Server keystore containing the server's private key and certificate
  - `server.pem`: Server certificate in PEM format (for browser import)
  - `server.storepasswd`: Server keystore password file

- `client/`: Client certificates for admin access
  - `admin.p12`: Client certificate in PKCS12 format (for browser import)
  - `admin.cer`: Client certificate in DER format

- `truststore/`: Truststore for client certificate authentication
  - `truststore.jks`: Truststore containing trusted client certificates

## Certificate Generation

To regenerate the certificates:

1. Server certificate:
```bash
keytool -genkeypair \
  -alias signserver \
  -keyalg RSA \
  -keysize 2048 \
  -validity 3650 \
  -keystore server/server.jks \
  -dname "CN=signserver,O=SignServer,C=SE" \
  -storepass changeit
```

2. Client certificate:
```bash
keytool -genkeypair \
  -alias admin \
  -keyalg RSA \
  -keysize 2048 \
  -validity 3650 \
  -keystore client/admin.jks \
  -dname "CN=admin,O=SignServer,C=SE" \
  -storepass changeit
```

3. Export and import into truststore:
```bash
keytool -exportcert \
  -alias admin \
  -file client/admin.cer \
  -keystore client/admin.jks \
  -storepass changeit

keytool -import \
  -alias admin \
  -file client/admin.cer \
  -keystore truststore/truststore.jks \
  -storepass signserver \
  -noprompt
```

4. Create PKCS12 for browser:
```bash
keytool -importkeystore \
  -srckeystore client/admin.jks \
  -destkeystore client/admin.p12 \
  -srcstoretype JKS \
  -deststoretype PKCS12 \
  -srcstorepass changeit \
  -deststorepass changeit \
  -srcalias admin \
  -destalias admin \
  -noprompt
```