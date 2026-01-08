# OpenLDAP Server

Este diretório contém a configuração para provisionar um servidor OpenLDAP usando Vagrant e Ansible.

## Visão Geral

O servidor OpenLDAP fornece serviços de autenticação LDAP com TLS para simular um ambiente corporativo de TI. Ele é implantado em um cluster K3s e acessível via `ldap.arq.unb.br`.

## Pré-requisitos

- VirtualBox
- Vagrant
- Ansible
- Certificados TLS copiados para `../ansible/roles/openldap_install/files/`

## Estrutura LDAP

### Domínio
- **Domain**: arq.unb.br
- **Base DN**: dc=arq,dc=unb,dc=br
- **Hostname**: ldap.arq.unb.br

### Usuários (4)
1. **interno** - Equipe de suporte
2. **evertonagilar** - Desenvolvedor e DevOps
3. **rancher** - Conta de serviço para Rancher
4. **argocd** - Conta de serviço para ArgoCD

### Grupos (6)
- developer - Equipe de Desenvolvimento
- devops - Equipe de DevOps
- support - Equipe de Suporte
- rh - Recursos Humanos
- comercial - Equipe de Vendas
- dba - Administradores de Banco de Dados

## Instalação

### Provisionar VM

```bash
vagrant up
```

### Executar Instalação Completa

```bash
ansible-playbook -i hosts.ini install-playbook.yml
```

## Credenciais Padrão

**Admin LDAP:**
- Username: `admin`
- Password: `ChangeMe123!` (definido em `../ansible/roles/openldap_install/defaults/main.yml`)
- DN: `cn=admin,dc=arq,dc=unb,dc=br`

**Usuários:**
- Senha padrão: `User@123`
- Todos os usuários devem alterar a senha no primeiro login

## Testando o Servidor

### Conectividade LDAP

```bash
ldapsearch -x -H ldaps://ldap.arq.unb.br -b "dc=arq,dc=unb,dc=br" \
  -D "cn=admin,dc=arq,dc=unb,dc=br" -W
```

### Autenticação de Usuário

```bash
ldapwhoami -x -H ldaps://ldap.arq.unb.br \
  -D "uid=evertonagilar,ou=users,dc=arq,dc=unb,dc=br" -W
```

### Listar Usuários

```bash
ldapsearch -x -H ldaps://ldap.arq.unb.br \
  -b "ou=users,dc=arq,dc=unb,dc=br" \
  -D "cn=admin,dc=arq,dc=unb,dc=br" -W
```

### Listar Grupos

```bash
ldapsearch -x -H ldaps://ldap.arq.unb.br \
  -b "ou=groups,dc=arq,dc=unb,dc=br" \
  -D "cn=admin,dc=arq,dc=unb,dc=br" -W
```

## Verificação do Deployment

### Verificar Pods

```bash
export KUBECONFIG=$(pwd)/kubeconfig
kubectl -n openldap get pods
kubectl -n openldap get svc
kubectl -n openldap get secret
```

### Logs do OpenLDAP

```bash
kubectl -n openldap logs -l app.kubernetes.io/name=openldap
```

## Customização

### Adicionar Usuários

Edite `../ansible/roles/openldap_install/vars/main.yml`:

```yaml
ldap_users:
  - uid: novousuario
    cn: Novo Usuario
    sn: Usuario
    mail: novousuario@arq.unb.br
    groups:
      - developer
```

### Adicionar Grupos

Edite `../ansible/roles/openldap_install/vars/main.yml`:

```yaml
ldap_groups:
  - name: novogrupo
    description: Descrição do Novo Grupo
```

Após modificar, execute novamente:

```bash
ansible-playbook -i hosts.ini ../ansible/install-openldap-playbook.yml
```

## Referências

- [OpenLDAP Documentation](https://www.openldap.org/doc/)
- [Bitnami OpenLDAP Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/openldap)
- [LDAP Authentication Guide](https://ldap.com/)
