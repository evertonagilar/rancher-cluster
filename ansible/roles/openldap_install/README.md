# OpenLDAP Installation

## Prerequisites

Before running the OpenLDAP installation playbook, you need to place the TLS certificates in the role's files directory.

### Required Certificates

Place the following files in `roles/openldap_install/files/`:

- `arq.unb.br.crt` - Wildcard certificate for *.arq.unb.br
- `arq.unb.br.key` - Private key for the certificate
- `ca-bundle.pem` - CA certificate bundle

These are the same certificates used for Vault and Rancher installations.

## Installation

Run the playbook:

```bash
ansible-playbook -i hosts.ini install-openldap-playbook.yml
```

## Configuration

### Default Credentials

**Admin Account:**
- Username: `admin`
- Password: Defined in `roles/openldap_install/defaults/main.yml` (default: `ChangeMe123!`)
- DN: `cn=admin,dc=arq,dc=unb,dc=br`

**Default User Password:**
- All users are created with the same initial password: `User@123`
- Users should change their password on first login

### Users

The following users are pre-configured:

1. **interno** - Support team member
   - Email: interno@arq.unb.br
   - Groups: support

2. **evertonagilar** - Developer and DevOps
   - Email: evertonagilar@arq.unb.br
   - Groups: developer, devops

3. **rancher** - Service account for Rancher
   - Email: rancher@arq.unb.br
   - Groups: services

4. **argocd** - Service account for ArgoCD
   - Email: argocd@arq.unb.br
   - Groups: services

### Groups

The following groups are available:

- `developer` - Development Team
- `devops` - DevOps Team
- `support` - Support Team
- `rh` - Human Resources
- `comercial` - Sales Team
- `dba` - Database Administrators
- `services` - Service Accounts

## Testing

### Test LDAP Connectivity

```bash
ldapsearch -x -H ldaps://ldap.arq.unb.br -b "dc=arq,dc=unb,dc=br" -D "cn=admin,dc=arq,dc=unb,dc=br" -W
```

### Test User Authentication

```bash
ldapwhoami -x -H ldaps://ldap.arq.unb.br -D "uid=evertonagilar,ou=users,dc=arq,dc=unb,dc=br" -W
```

### List All Users

```bash
ldapsearch -x -H ldaps://ldap.arq.unb.br -b "ou=users,dc=arq,dc=unb,dc=br" -D "cn=admin,dc=arq,dc=unb,dc=br" -W
```

### List All Groups

```bash
ldapsearch -x -H ldaps://ldap.arq.unb.br -b "ou=groups,dc=arq,dc=unb,dc=br" -D "cn=admin,dc=arq,dc=unb,dc=br" -W
```

## Security Notes

> [!WARNING]
> The default passwords in `defaults/main.yml` are for testing purposes only. For production use:
> 1. Use Ansible Vault to encrypt sensitive variables
> 2. Change all default passwords
> 3. Implement password policies
> 4. Enable audit logging

## Customization

### Adding New Users

Edit `roles/openldap_install/vars/main.yml` and add entries to the `ldap_users` list:

```yaml
ldap_users:
  - uid: newuser
    cn: New User
    sn: User
    mail: newuser@arq.unb.br
    groups:
      - developer
```

### Adding New Groups

Edit `roles/openldap_install/vars/main.yml` and add entries to the `ldap_groups` list:

```yaml
ldap_groups:
  - name: newgroup
    description: New Group Description
```

## Troubleshooting

### Check OpenLDAP Pods

```bash
kubectl -n openldap get pods
kubectl -n openldap logs <pod-name>
```

### Check TLS Secret

```bash
kubectl -n openldap get secret ldap-tls
```

### Access OpenLDAP Shell

```bash
kubectl -n openldap exec -it <pod-name> -- bash
```
