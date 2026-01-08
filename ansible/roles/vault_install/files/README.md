# Vault Installation - Certificate Files

This directory should contain the following certificate files for Vault TLS configuration:

## Required Files

1. **tls.crt** - Wildcard certificate for `*.arq.unb.br`
2. **tls.key** - Private key for the certificate
3. **intermediate.pem** - Intermediate CA certificate
4. **gs_root.pem** - Root CA certificate (GlobalSign or your CA root)

## Notes

- These files are **not** included in version control for security reasons
- You must manually place these files in this directory before running the `install-vault-playbook.yml`
- The certificate should be a wildcard certificate that covers `vault.arq.unb.br`
- The role will automatically create a CA bundle from the intermediate and root certificates
- The CA bundle will be used to configure the `VAULT_CACERT` environment variable

## File Permissions

The role will automatically set appropriate permissions:
- Certificates (`.crt`, `.pem`): `0644`
- Private key (`.key`): `0600`
