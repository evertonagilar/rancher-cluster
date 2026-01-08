# Tutorial HashiCorp Vault - AgilarIT

## Sobre este Tutorial

Este tutorial foi criado para desenvolvedores da **AgilarIT** que estão começando a trabalhar com HashiCorp Vault. O conteúdo é baseado no tutorial oficial da HashiCorp, adaptado para o contexto da nossa empresa.

**Público-alvo**: Desenvolvedores sem experiência prévia com Vault  
**Tempo estimado**: 6-8 horas  
**Pré-requisitos**: Conhecimentos básicos de Linux, linha de comando e conceitos de segurança

---

## Sumário

1. [Introdução ao Vault](#1-introdução-ao-vault) - ⭐ Dificuldade: Básica
2. [Instalação e Configuração Inicial](#2-instalação-e-configuração-inicial) - ⭐ Dificuldade: Básica
3. [Conceitos Fundamentais](#3-conceitos-fundamentais) - ⭐⭐ Dificuldade: Intermediária
4. [Secrets Engines - KV (Key-Value)](#4-secrets-engines---kv-key-value) - ⭐⭐ Dificuldade: Intermediária
5. [Autenticação e Políticas](#5-autenticação-e-políticas) - ⭐⭐⭐ Dificuldade: Avançada
6. [PKI - Infraestrutura de Chaves Públicas](#6-pki---infraestrutura-de-chaves-públicas) - ⭐⭐⭐⭐ Dificuldade: Avançada
7. [Database Secrets Engine](#7-database-secrets-engine) - ⭐⭐⭐ Dificuldade: Avançada
8. [Integração com Kubernetes](#8-integração-com-kubernetes) - ⭐⭐⭐⭐ Dificuldade: Avançada
9. [Transit Engine - Encryption as a Service](#9-transit-engine---encryption-as-a-service) - ⭐⭐⭐ Dificuldade: Avançada
10. [Casos de Uso na AgilarIT](#10-casos-de-uso-na-agilarit) - ⭐⭐ Dificuldade: Intermediária

---

## Sobre a AgilarIT

**AgilarIT** é uma pequena empresa de desenvolvimento de software com os seguintes setores:

### Estrutura Organizacional

- **Desenvolvimento**: evertonagilar, rafael
- **DevOps**: evertonagilar
- **RH**: thaise
- **Comercial**: mateus
- **Suporte**: (em expansão)

### Infraestrutura

- **Clusters Kubernetes**:
  - Cluster Rancher (gerenciamento)
  - Cluster RKE2 (produção)
- **Aplicações**:
  - SCI (Sistema Comercial Integrado)
  - iBoleto (Emissão de Boletos)
- **Banco de Dados**: Oracle
- **Sistema Operacional**: Ubuntu (todas as VMs)

### Usuários Especiais

- **interno**: Usuário para playbooks Ansible
- **ubuntu**: Usuário padrão do sistema
- **Usuários de Serviço**: rancher, argocd, gitlab

### Política de Estagiários

A AgilarIT aceita estagiários periodicamente, por isso usamos uma role `estagiario` para facilitar o gerenciamento de permissões temporárias.

---

## 1. Introdução ao Vault

**Dificuldade**: ⭐ Básica  
**Tempo estimado**: 30 minutos

### 1.1 O que é o Vault?

HashiCorp Vault é uma ferramenta para gerenciar segredos e proteger dados sensíveis. Pense nele como um "cofre digital" centralizado onde você armazena:

- Senhas de banco de dados
- Chaves de API
- Certificados TLS/SSL
- Tokens de acesso
- Credenciais de cloud providers
- Qualquer informação sensível

### 1.2 Por que usar Vault na AgilarIT?

#### Desafios Atuais

Sem o Vault, a AgilarIT enfrenta vários desafios:

1. **Secrets Espalhados**: Senhas em arquivos de configuração, variáveis de ambiente, scripts
2. **Sem Rotação**: Credenciais nunca expiram ou são trocadas
3. **Sem Auditoria**: Difícil saber quem acessou o quê
4. **Sem Controle Granular**: Todos têm acesso a tudo ou a nada
5. **Certificados Manuais**: Processo manual e propenso a erros

#### Benefícios do Vault

1. **Centralização**: Um único lugar para todos os segredos
2. **Criptografia**: Dados criptografados em repouso e em trânsito
3. **Controle de Acesso**: Políticas granulares por usuário/aplicação
4. **Auditoria Completa**: Log de todas as operações
5. **Secrets Dinâmicos**: Credenciais temporárias geradas sob demanda
6. **PKI Automatizado**: Geração e renovação automática de certificados
7. **Integração Kubernetes**: Injeção automática de secrets em pods

### 1.3 Arquitetura do Vault

```
┌─────────────────────────────────────────────────────┐
│                    Vault Server                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ Auth Methods │  │   Policies   │  │  Secrets  │ │
│  │              │  │              │  │  Engines  │ │
│  │ - UserPass   │  │ - ACL        │  │ - KV      │ │
│  │ - LDAP       │  │ - Roles      │  │ - PKI     │ │
│  │ - Kubernetes │  │              │  │ - Database│ │
│  │ - AppRole    │  │              │  │ - Transit │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │         Storage Backend (Raft/Consul)        │  │
│  │         (Encrypted at Rest)                  │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### 1.4 Conceitos Básicos

- **Seal/Unseal**: Vault inicia "selado" (criptografado). Precisa ser "deselado" para uso
- **Token**: Credencial de autenticação no Vault
- **Policy**: Regras de acesso (quem pode fazer o quê)
- **Secret**: Qualquer dado sensível armazenado
- **Path**: Localização de um secret (ex: `secret/data/sci/database`)
- **Lease**: Tempo de vida de um secret dinâmico

---

## 2. Instalação e Configuração Inicial

**Dificuldade**: ⭐ Básica  
**Tempo estimado**: 20 minutos

### 2.1 Instalação do Vault

```bash
# Baixar Vault (versão 1.15.4)
wget https://releases.hashicorp.com/vault/1.15.4/vault_1.15.4_linux_amd64.zip

# Descompactar
unzip vault_1.15.4_linux_amd64.zip

# Mover para /usr/local/bin
sudo mv vault /usr/local/bin/

# Verificar instalação
vault version
```

### 2.2 Iniciar Servidor de Desenvolvimento

> **⚠️ IMPORTANTE**: O modo dev é APENAS para aprendizado. Nunca use em produção!

```bash
# Iniciar Vault em modo dev
vault server -dev

# Em outro terminal, configurar variáveis de ambiente
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'  # Token exibido ao iniciar o servidor

# Verificar status
vault status
```

**Saída esperada**:
```
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.15.4
Storage Type    inmem
Cluster Name    vault-cluster-abc123
Cluster ID      12345678-1234-1234-1234-123456789012
HA Enabled      false
```

### 2.3 Primeiros Comandos

```bash
# Escrever um secret
vault kv put secret/hello foo=world

# Ler um secret
vault kv get secret/hello

# Listar secrets
vault kv list secret/

# Deletar um secret
vault kv delete secret/hello
```

---

## 3. Conceitos Fundamentais

**Dificuldade**: ⭐⭐ Intermediária  
**Tempo estimado**: 45 minutos

### 3.1 Paths e Namespaces

No Vault, tudo é organizado em **paths** (caminhos), similar a um sistema de arquivos:

```
secret/
├── agilarit/
│   ├── desenvolvimento/
│   │   ├── sci/
│   │   │   ├── database
│   │   │   └── api-keys
│   │   └── iboleto/
│   │       ├── database
│   │       └── api-keys
│   ├── devops/
│   │   ├── rancher/
│   │   └── argocd/
│   ├── rh/
│   └── comercial/
```

### 3.2 Secrets Engines

Secrets engines são plugins que armazenam, geram ou criptografam dados. Cada engine é montado em um path específico.

**Tipos principais**:

1. **KV (Key-Value)**: Armazena secrets estáticos
2. **PKI**: Gera certificados X.509
3. **Database**: Gera credenciais dinâmicas de banco
4. **Transit**: Criptografia como serviço
5. **AWS/Azure/GCP**: Credenciais dinâmicas de cloud

```bash
# Listar secrets engines habilitados
vault secrets list

# Habilitar novo KV engine
vault secrets enable -path=agilarit kv-v2

# Desabilitar engine
vault secrets disable agilarit
```

### 3.3 Authentication Methods

Auth methods permitem que usuários e aplicações se autentiquem no Vault.

```bash
# Listar métodos de autenticação
vault auth list

# Habilitar userpass (usuário/senha)
vault auth enable userpass

# Habilitar LDAP
vault auth enable ldap

# Habilitar Kubernetes
vault auth enable kubernetes
```

### 3.4 Policies (Políticas)

Policies definem o que cada usuário/aplicação pode fazer.

**Exemplo de policy**:

```hcl
# policy-desenvolvedor.hcl
path "secret/data/agilarit/desenvolvimento/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/data/agilarit/rh/*" {
  capabilities = ["deny"]
}
```

**Capabilities disponíveis**:
- `create`: Criar novos secrets
- `read`: Ler secrets
- `update`: Atualizar secrets existentes
- `delete`: Deletar secrets
- `list`: Listar secrets
- `sudo`: Operações administrativas
- `deny`: Negar explicitamente acesso

---

## 4. Secrets Engines - KV (Key-Value)

**Dificuldade**: ⭐⭐ Intermediária  
**Tempo estimado**: 1 hora

### 4.1 KV Version 2 (Versionado)

O KV v2 mantém versões dos secrets, permitindo recuperar valores antigos.

```bash
# Habilitar KV v2
vault secrets enable -path=agilarit kv-v2

# Escrever secret
vault kv put agilarit/sci/database \
  username="sci_user" \
  password="SuperSecret123!" \
  host="oracle-prod.agilarit.local" \
  port="1521" \
  database="SCIPROD"

# Ler secret
vault kv get agilarit/sci/database

# Ler apenas um campo
vault kv get -field=password agilarit/sci/database

# Ler em formato JSON
vault kv get -format=json agilarit/sci/database
```

### 4.2 Versionamento

```bash
# Atualizar secret (cria versão 2)
vault kv put agilarit/sci/database \
  username="sci_user" \
  password="NewPassword456!" \
  host="oracle-prod.agilarit.local" \
  port="1521" \
  database="SCIPROD"

# Ver histórico de versões
vault kv metadata get agilarit/sci/database

# Ler versão específica
vault kv get -version=1 agilarit/sci/database

# Deletar versão específica (soft delete)
vault kv delete -versions=2 agilarit/sci/database

# Recuperar versão deletada
vault kv undelete -versions=2 agilarit/sci/database

# Destruir versão permanentemente
vault kv destroy -versions=1 agilarit/sci/database
```

### 4.3 Metadata e Configuração

```bash
# Configurar número máximo de versões
vault kv metadata put -max-versions=5 agilarit/sci/database

# Configurar tempo de deleção automática
vault kv metadata put -delete-version-after=30d agilarit/sci/database

# Ver metadata
vault kv metadata get agilarit/sci/database
```

### 4.4 Estrutura de Secrets da AgilarIT

```bash
# Secrets do SCI
vault kv put agilarit/sci/database \
  username="sci_user" \
  password="SciPass123!" \
  connection_string="oracle://sci_user@oracle-prod:1521/SCIPROD"

vault kv put agilarit/sci/api-keys \
  correios_api="ABC123XYZ" \
  sefaz_api="DEF456UVW"

# Secrets do iBoleto
vault kv put agilarit/iboleto/database \
  username="iboleto_user" \
  password="IboletoPass456!" \
  connection_string="oracle://iboleto_user@oracle-prod:1521/IBOLETOPROD"

vault kv put agilarit/iboleto/api-keys \
  banco_brasil="GHI789RST" \
  itau="JKL012MNO"

# Secrets do Rancher
vault kv put agilarit/devops/rancher \
  admin_password="RancherAdmin789!" \
  api_token="token-xxxxx:yyyyy"

# Secrets do ArgoCD
vault kv put agilarit/devops/argocd \
  admin_password="ArgoAdmin321!" \
  github_token="ghp_xxxxxxxxxxxx"
```

---

## 5. Autenticação e Políticas

**Dificuldade**: ⭐⭐⭐ Avançada  
**Tempo estimado**: 1.5 horas

### 5.1 UserPass Authentication

```bash
# Habilitar userpass
vault auth enable userpass

# Criar usuários da AgilarIT
vault write auth/userpass/users/evertonagilar \
  password="everton123" \
  policies="desenvolvedor,devops"

vault write auth/userpass/users/rafael \
  password="rafael123" \
  policies="desenvolvedor"

vault write auth/userpass/users/thaise \
  password="thaise123" \
  policies="rh"

vault write auth/userpass/users/mateus \
  password="mateus123" \
  policies="comercial"

# Criar role para estagiários
vault write auth/userpass/users/estagiario \
  password="estagiario123" \
  policies="estagiario"
```

### 5.2 Criando Policies

#### Policy: Desenvolvedor

```bash
cat > policy-desenvolvedor.hcl <<EOF
# Acesso total aos secrets de desenvolvimento
path "agilarit/data/sci/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "agilarit/data/iboleto/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Apenas leitura em devops
path "agilarit/data/devops/*" {
  capabilities = ["read", "list"]
}

# Sem acesso a RH e Comercial
path "agilarit/data/rh/*" {
  capabilities = ["deny"]
}

path "agilarit/data/comercial/*" {
  capabilities = ["deny"]
}
EOF

vault policy write desenvolvedor policy-desenvolvedor.hcl
```

#### Policy: DevOps

```bash
cat > policy-devops.hcl <<EOF
# Acesso total a tudo de devops
path "agilarit/data/devops/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Leitura em desenvolvimento
path "agilarit/data/sci/*" {
  capabilities = ["read", "list"]
}

path "agilarit/data/iboleto/*" {
  capabilities = ["read", "list"]
}

# Gerenciar PKI
path "pki/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Gerenciar database secrets
path "database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

vault policy write devops policy-devops.hcl
```

#### Policy: RH

```bash
cat > policy-rh.hcl <<EOF
# Acesso apenas a secrets de RH
path "agilarit/data/rh/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Sem acesso a outros setores
path "agilarit/data/desenvolvimento/*" {
  capabilities = ["deny"]
}

path "agilarit/data/devops/*" {
  capabilities = ["deny"]
}

path "agilarit/data/comercial/*" {
  capabilities = ["deny"]
}
EOF

vault policy write rh policy-rh.hcl
```

#### Policy: Estagiário

```bash
cat > policy-estagiario.hcl <<EOF
# Apenas leitura em desenvolvimento
path "agilarit/data/sci/*" {
  capabilities = ["read", "list"]
}

path "agilarit/data/iboleto/*" {
  capabilities = ["read", "list"]
}

# Sem acesso a outros setores
path "agilarit/data/devops/*" {
  capabilities = ["deny"]
}

path "agilarit/data/rh/*" {
  capabilities = ["deny"]
}

path "agilarit/data/comercial/*" {
  capabilities = ["deny"]
}
EOF

vault policy write estagiario policy-estagiario.hcl
```

### 5.3 Testando Autenticação

```bash
# Login como desenvolvedor
vault login -method=userpass username=rafael
# Digite a senha quando solicitado

# Testar acesso
vault kv get agilarit/sci/database  # ✅ Deve funcionar
vault kv get agilarit/rh/folha      # ❌ Deve falhar (permission denied)

# Logout
vault token revoke -self

# Login como DevOps
vault login -method=userpass username=evertonagilar
```

### 5.4 AppRole para Aplicações

AppRole é usado para autenticação de máquinas/aplicações.

```bash
# Habilitar AppRole
vault auth enable approle

# Criar role para SCI
vault write auth/approle/role/sci \
  token_policies="app-sci" \
  token_ttl=1h \
  token_max_ttl=4h

# Criar role para iBoleto
vault write auth/approle/role/iboleto \
  token_policies="app-iboleto" \
  token_ttl=1h \
  token_max_ttl=4h

# Obter Role ID
vault read auth/approle/role/sci/role-id

# Gerar Secret ID
vault write -f auth/approle/role/sci/secret-id

# Autenticar com AppRole
vault write auth/approle/login \
  role_id="<role-id>" \
  secret_id="<secret-id>"
```

---

## 6. PKI - Infraestrutura de Chaves Públicas

**Dificuldade**: ⭐⭐⭐⭐ Avançada  
**Tempo estimado**: 2 horas

### 6.1 Visão Geral do PKI

O PKI engine permite que o Vault funcione como uma Autoridade Certificadora (CA), gerando e assinando certificados automaticamente.

**Hierarquia de CAs da AgilarIT**:

```
Root CA (offline, 10 anos)
  └── Intermediate CA (online, 5 anos)
        ├── Server Certificates (1 ano)
        ├── Client Certificates (1 ano)
        └── Service Certificates (90 dias)
```

### 6.2 Criar Root CA

```bash
# Habilitar PKI para Root CA
vault secrets enable -path=pki_root pki

# Configurar TTL máximo (10 anos)
vault secrets tune -max-lease-ttl=87600h pki_root

# Gerar Root CA
vault write -field=certificate pki_root/root/generate/internal \
  common_name="AgilarIT Root CA" \
  organization="AgilarIT Desenvolvimento de Software" \
  ou="Infraestrutura" \
  country="BR" \
  locality="Brasilia" \
  province="DF" \
  ttl=87600h > agilarit_root_ca.crt

# Configurar URLs da CA
vault write pki_root/config/urls \
  issuing_certificates="http://vault.agilarit.local:8200/v1/pki_root/ca" \
  crl_distribution_points="http://vault.agilarit.local:8200/v1/pki_root/crl"
```

### 6.3 Criar Intermediate CA

```bash
# Habilitar PKI para Intermediate CA
vault secrets enable -path=pki_int pki

# Configurar TTL máximo (5 anos)
vault secrets tune -max-lease-ttl=43800h pki_int

# Gerar CSR para Intermediate CA
vault write -field=csr pki_int/intermediate/generate/internal \
  common_name="AgilarIT Intermediate CA" \
  organization="AgilarIT Desenvolvimento de Software" \
  ou="Infraestrutura" \
  country="BR" \
  locality="Brasilia" \
  province="DF" \
  ttl=43800h > pki_intermediate.csr

# Assinar CSR com Root CA
vault write -field=certificate pki_root/root/sign-intermediate \
  csr=@pki_intermediate.csr \
  format=pem_bundle \
  ttl=43800h > intermediate.cert.pem

# Importar certificado assinado
vault write pki_int/intermediate/set-signed \
  certificate=@intermediate.cert.pem

# Configurar URLs
vault write pki_int/config/urls \
  issuing_certificates="http://vault.agilarit.local:8200/v1/pki_int/ca" \
  crl_distribution_points="http://vault.agilarit.local:8200/v1/pki_int/crl"
```

### 6.4 Criar Roles para Certificados

#### Role: Servidores Internos

```bash
vault write pki_int/roles/agilarit-servers \
  allowed_domains="agilarit.local,agilarit.com.br" \
  allow_subdomains=true \
  max_ttl=8760h \
  key_bits=2048 \
  key_type=rsa \
  allow_ip_sans=true \
  server_flag=true \
  client_flag=false \
  enforce_hostnames=true
```

#### Role: Aplicações (SCI, iBoleto)

```bash
vault write pki_int/roles/agilarit-apps \
  allowed_domains="sci.agilarit.local,iboleto.agilarit.local" \
  allow_subdomains=true \
  max_ttl=2160h \
  key_bits=2048 \
  key_type=rsa \
  allow_ip_sans=true \
  server_flag=true \
  client_flag=true
```

#### Role: Kubernetes Services

```bash
vault write pki_int/roles/kubernetes-services \
  allowed_domains="*.svc.cluster.local,*.agilarit.local" \
  allow_subdomains=true \
  allow_glob_domains=true \
  max_ttl=2160h \
  key_bits=2048 \
  server_flag=true \
  client_flag=true
```

### 6.5 Gerar Certificados

#### Certificado para Rancher

```bash
# Gerar certificado
vault write -format=json pki_int/issue/agilarit-servers \
  common_name="rancher.agilarit.local" \
  alt_names="rancher.agilarit.com.br" \
  ip_sans="192.168.56.101" \
  ttl=8760h > rancher-cert.json

# Extrair componentes
cat rancher-cert.json | jq -r .data.certificate > rancher.crt
cat rancher-cert.json | jq -r .data.private_key > rancher.key
cat rancher-cert.json | jq -r .data.ca_chain[] > rancher-ca.crt
```

#### Certificado para SCI

```bash
vault write -format=json pki_int/issue/agilarit-apps \
  common_name="sci.agilarit.local" \
  alt_names="sci-api.agilarit.local,sci-web.agilarit.local" \
  ttl=2160h > sci-cert.json

cat sci-cert.json | jq -r .data.certificate > sci.crt
cat sci-cert.json | jq -r .data.private_key > sci.key
cat sci-cert.json | jq -r .data.ca_chain[] > sci-ca.crt
```

#### Certificado para iBoleto

```bash
vault write -format=json pki_int/issue/agilarit-apps \
  common_name="iboleto.agilarit.local" \
  alt_names="iboleto-api.agilarit.local" \
  ttl=2160h > iboleto-cert.json

cat iboleto-cert.json | jq -r .data.certificate > iboleto.crt
cat iboleto-cert.json | jq -r .data.private_key > iboleto.key
cat iboleto-cert.json | jq -r .data.ca_chain[] > iboleto-ca.crt
```

### 6.6 Renovação de Certificados

```bash
# Listar certificados emitidos
vault list pki_int/certs

# Ver detalhes de um certificado
vault read pki_int/cert/<serial-number>

# Revogar certificado
vault write pki_int/revoke serial_number="<serial-number>"

# Renovar certificado (gerar novo)
vault write -format=json pki_int/issue/agilarit-servers \
  common_name="rancher.agilarit.local" \
  alt_names="rancher.agilarit.com.br" \
  ip_sans="192.168.56.101" \
  ttl=8760h > rancher-cert-renewed.json
```

### 6.7 Verificar Certificados

```bash
# Ver informações do certificado
openssl x509 -in rancher.crt -text -noout

# Verificar cadeia de certificados
openssl verify -CAfile rancher-ca.crt rancher.crt

# Testar conexão TLS
openssl s_client -connect rancher.agilarit.local:443 -CAfile rancher-ca.crt
```

---

## 7. Database Secrets Engine

**Dificuldade**: ⭐⭐⭐ Avançada  
**Tempo estimado**: 1 hora

### 7.1 Configurar Database Engine

```bash
# Habilitar database secrets engine
vault secrets enable database

# Configurar conexão com Oracle (SCI)
vault write database/config/oracle-sci \
  plugin_name=oracle-database-plugin \
  connection_url="{{username}}/{{password}}@oracle-prod.agilarit.local:1521/SCIPROD" \
  allowed_roles="sci-app,sci-readonly" \
  username="vault_admin" \
  password="VaultAdminPass123!"

# Configurar conexão com Oracle (iBoleto)
vault write database/config/oracle-iboleto \
  plugin_name=oracle-database-plugin \
  connection_url="{{username}}/{{password}}@oracle-prod.agilarit.local:1521/IBOLETOPROD" \
  allowed_roles="iboleto-app,iboleto-readonly" \
  username="vault_admin" \
  password="VaultAdminPass123!"
```

### 7.2 Criar Roles de Banco de Dados

#### Role: SCI Application

```bash
vault write database/roles/sci-app \
  db_name=oracle-sci \
  creation_statements="CREATE USER {{username}} IDENTIFIED BY {{password}}; \
    GRANT CONNECT, RESOURCE TO {{username}}; \
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCI.* TO {{username}};" \
  default_ttl="1h" \
  max_ttl="24h"
```

#### Role: SCI Read-Only

```bash
vault write database/roles/sci-readonly \
  db_name=oracle-sci \
  creation_statements="CREATE USER {{username}} IDENTIFIED BY {{password}}; \
    GRANT CONNECT TO {{username}}; \
    GRANT SELECT ON SCI.* TO {{username}};" \
  default_ttl="8h" \
  max_ttl="24h"
```

#### Role: iBoleto Application

```bash
vault write database/roles/iboleto-app \
  db_name=oracle-iboleto \
  creation_statements="CREATE USER {{username}} IDENTIFIED BY {{password}}; \
    GRANT CONNECT, RESOURCE TO {{username}}; \
    GRANT SELECT, INSERT, UPDATE, DELETE ON IBOLETO.* TO {{username}};" \
  default_ttl="1h" \
  max_ttl="24h"
```

### 7.3 Gerar Credenciais Dinâmicas

```bash
# Gerar credenciais para SCI
vault read database/creds/sci-app

# Saída:
# Key                Value
# ---                -----
# lease_id           database/creds/sci-app/abc123
# lease_duration     1h
# lease_renewable    true
# password           A1a-xyz789random
# username           v-root-sci-app-abc123xyz

# Gerar credenciais read-only
vault read database/creds/sci-readonly

# Renovar lease
vault lease renew database/creds/sci-app/abc123

# Revogar credenciais
vault lease revoke database/creds/sci-app/abc123
```

### 7.4 Rotação de Credenciais Root

```bash
# Rotacionar senha do vault_admin
vault write -f database/rotate-root/oracle-sci
vault write -f database/rotate-root/oracle-iboleto
```

---

## 8. Integração com Kubernetes

**Dificuldade**: ⭐⭐⭐⭐ Avançada  
**Tempo estimado**: 2 horas

### 8.1 Configurar Kubernetes Auth

```bash
# Habilitar Kubernetes auth
vault auth enable kubernetes

# Configurar auth method (executar de dentro do cluster)
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token
```

### 8.2 Criar Policies para Aplicações

#### Policy: SCI

```bash
cat > policy-app-sci.hcl <<EOF
# Acesso aos secrets do SCI
path "agilarit/data/sci/*" {
  capabilities = ["read", "list"]
}

# Gerar credenciais de banco
path "database/creds/sci-app" {
  capabilities = ["read"]
}

# Gerar certificados
path "pki_int/issue/agilarit-apps" {
  capabilities = ["create", "update"]
}
EOF

vault policy write app-sci policy-app-sci.hcl
```

#### Policy: iBoleto

```bash
cat > policy-app-iboleto.hcl <<EOF
# Acesso aos secrets do iBoleto
path "agilarit/data/iboleto/*" {
  capabilities = ["read", "list"]
}

# Gerar credenciais de banco
path "database/creds/iboleto-app" {
  capabilities = ["read"]
}

# Gerar certificados
path "pki_int/issue/agilarit-apps" {
  capabilities = ["create", "update"]
}
EOF

vault policy write app-iboleto policy-app-iboleto.hcl
```

### 8.3 Criar Kubernetes Roles

```bash
# Role para SCI
vault write auth/kubernetes/role/sci \
  bound_service_account_names=sci \
  bound_service_account_namespaces=production \
  policies=app-sci \
  ttl=1h

# Role para iBoleto
vault write auth/kubernetes/role/iboleto \
  bound_service_account_names=iboleto \
  bound_service_account_namespaces=production \
  policies=app-iboleto \
  ttl=1h
```

### 8.4 Vault Agent Injector

#### Instalar Vault Helm Chart

```bash
# Adicionar repo Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Instalar Vault com Agent Injector
helm install vault hashicorp/vault \
  --set "injector.enabled=true" \
  --set "server.dev.enabled=false" \
  --set "server.ha.enabled=true" \
  --namespace vault \
  --create-namespace
```

#### Deployment SCI com Vault Injection

```yaml
# sci-deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sci
  namespace: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sci
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sci
  template:
    metadata:
      labels:
        app: sci
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "sci"
        vault.hashicorp.com/agent-inject-secret-database: "database/creds/sci-app"
        vault.hashicorp.com/agent-inject-template-database: |
          {{- with secret "database/creds/sci-app" -}}
          export DB_USERNAME="{{ .Data.username }}"
          export DB_PASSWORD="{{ .Data.password }}"
          export DB_CONNECTION="oracle://{{ .Data.username }}:{{ .Data.password }}@oracle-prod:1521/SCIPROD"
          {{- end }}
        vault.hashicorp.com/agent-inject-secret-config: "agilarit/data/sci/api-keys"
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "agilarit/data/sci/api-keys" -}}
          export CORREIOS_API="{{ .Data.data.correios_api }}"
          export SEFAZ_API="{{ .Data.data.sefaz_api }}"
          {{- end }}
    spec:
      serviceAccountName: sci
      containers:
      - name: sci
        image: agilarit/sci:latest
        command: ["/bin/sh"]
        args:
          - -c
          - |
            source /vault/secrets/database
            source /vault/secrets/config
            exec /app/sci
```

#### Deployment iBoleto com Vault Injection

```yaml
# iboleto-deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: iboleto
  namespace: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iboleto
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: iboleto
  template:
    metadata:
      labels:
        app: iboleto
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "iboleto"
        vault.hashicorp.com/agent-inject-secret-database: "database/creds/iboleto-app"
        vault.hashicorp.com/agent-inject-template-database: |
          {{- with secret "database/creds/iboleto-app" -}}
          {
            "username": "{{ .Data.username }}",
            "password": "{{ .Data.password }}",
            "connection_string": "oracle://{{ .Data.username }}:{{ .Data.password }}@oracle-prod:1521/IBOLETOPROD"
          }
          {{- end }}
        vault.hashicorp.com/agent-inject-secret-api-keys: "agilarit/data/iboleto/api-keys"
        vault.hashicorp.com/agent-inject-template-api-keys: |
          {{- with secret "agilarit/data/iboleto/api-keys" -}}
          {
            "banco_brasil": "{{ .Data.data.banco_brasil }}",
            "itau": "{{ .Data.data.itau }}"
          }
          {{- end }}
    spec:
      serviceAccountName: iboleto
      containers:
      - name: iboleto
        image: agilarit/iboleto:latest
        env:
        - name: CONFIG_PATH
          value: /vault/secrets
```

### 8.5 Vault CSI Provider

Alternativa ao Agent Injector usando CSI (Container Storage Interface).

```yaml
# sci-secretproviderclass.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: sci-vault-secrets
  namespace: production
spec:
  provider: vault
  parameters:
    vaultAddress: "http://vault.vault.svc.cluster.local:8200"
    roleName: "sci"
    objects: |
      - objectName: "database-creds"
        secretPath: "database/creds/sci-app"
        secretKey: "username"
      - objectName: "database-password"
        secretPath: "database/creds/sci-app"
        secretKey: "password"
      - objectName: "api-keys"
        secretPath: "agilarit/data/sci/api-keys"
        secretKey: "correios_api"
```

---

## 9. Transit Engine - Encryption as a Service

**Dificuldade**: ⭐⭐⭐ Avançada  
**Tempo estimado**: 45 minutos

### 9.1 Habilitar Transit Engine

```bash
# Habilitar transit engine
vault secrets enable transit

# Criar chave de criptografia para SCI
vault write -f transit/keys/sci

# Criar chave de criptografia para iBoleto
vault write -f transit/keys/iboleto

# Criar chave para dados de RH (sensíveis)
vault write -f transit/keys/rh-dados-sensiveis
```

### 9.2 Criptografar Dados

```bash
# Criptografar CPF de cliente
vault write transit/encrypt/sci \
  plaintext=$(echo "123.456.789-00" | base64)

# Saída:
# Key            Value
# ---            -----
# ciphertext     vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM96XVZ...

# Criptografar número de cartão
vault write transit/encrypt/sci \
  plaintext=$(echo "4111111111111111" | base64)
```

### 9.3 Descriptografar Dados

```bash
# Descriptografar
vault write transit/decrypt/sci \
  ciphertext="vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM96XVZ..."

# Saída (base64):
# Key          Value
# ---          -----
# plaintext    MTIzLjQ1Ni43ODktMDA=

# Decodificar base64
echo "MTIzLjQ1Ni43ODktMDA=" | base64 -d
# 123.456.789-00
```

### 9.4 Rotação de Chaves

```bash
# Rotacionar chave
vault write -f transit/keys/sci/rotate

# Ver versões da chave
vault read transit/keys/sci

# Configurar versão mínima para descriptografia
vault write transit/keys/sci/config min_decryption_version=2

# Configurar versão mínima para criptografia
vault write transit/keys/sci/config min_encryption_version=3
```

### 9.5 Uso em Aplicação

#### Exemplo Python

```python
import hvac
import base64

# Conectar ao Vault
client = hvac.Client(url='http://vault.agilarit.local:8200')
client.token = 'seu-token-aqui'

# Criptografar CPF
cpf = "123.456.789-00"
cpf_b64 = base64.b64encode(cpf.encode()).decode()

encrypted = client.secrets.transit.encrypt_data(
    name='sci',
    plaintext=cpf_b64
)
ciphertext = encrypted['data']['ciphertext']
print(f"Criptografado: {ciphertext}")

# Descriptografar
decrypted = client.secrets.transit.decrypt_data(
    name='sci',
    ciphertext=ciphertext
)
plaintext_b64 = decrypted['data']['plaintext']
cpf_original = base64.b64decode(plaintext_b64).decode()
print(f"Descriptografado: {cpf_original}")
```

---

## 10. Casos de Uso na AgilarIT

**Dificuldade**: ⭐⭐ Intermediária  
**Tempo estimado**: 1 hora

### 10.1 Fluxo Completo: Deploy do SCI

```bash
# 1. DevOps cria secrets iniciais
vault login -method=userpass username=evertonagilar

vault kv put agilarit/sci/database \
  host="oracle-prod.agilarit.local" \
  port="1521" \
  database="SCIPROD"

vault kv put agilarit/sci/api-keys \
  correios_api="ABC123" \
  sefaz_api="DEF456"

# 2. Configurar database engine
vault write database/config/oracle-sci \
  plugin_name=oracle-database-plugin \
  connection_url="{{username}}/{{password}}@oracle-prod:1521/SCIPROD" \
  allowed_roles="sci-app" \
  username="vault_admin" \
  password="VaultPass123!"

vault write database/roles/sci-app \
  db_name=oracle-sci \
  creation_statements="CREATE USER {{username}} IDENTIFIED BY {{password}}; \
    GRANT CONNECT, RESOURCE TO {{username}}; \
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCI.* TO {{username}};" \
  default_ttl="1h" \
  max_ttl="24h"

# 3. Configurar Kubernetes auth
vault write auth/kubernetes/role/sci \
  bound_service_account_names=sci \
  bound_service_account_namespaces=production \
  policies=app-sci \
  ttl=1h

# 4. Deploy no Kubernetes
kubectl apply -f sci-deployment.yaml

# 5. Verificar injeção de secrets
kubectl exec -it deployment/sci -n production -- cat /vault/secrets/database
```

### 10.2 Onboarding de Estagiário

```bash
# 1. RH cria usuário
vault login -method=userpass username=thaise

vault write auth/userpass/users/joao-estagiario \
  password="temp123" \
  policies="estagiario"

# 2. Estagiário faz login
vault login -method=userpass username=joao-estagiario

# 3. Estagiário pode ler secrets de dev
vault kv get agilarit/sci/api-keys  # ✅ Funciona

# 4. Estagiário NÃO pode modificar
vault kv put agilarit/sci/test foo=bar  # ❌ Permission denied

# 5. Ao final do estágio, DevOps remove acesso
vault login -method=userpass username=evertonagilar
vault delete auth/userpass/users/joao-estagiario
```

### 10.3 Renovação de Certificado do Rancher

```bash
# 1. DevOps verifica expiração
openssl x509 -in rancher.crt -noout -enddate

# 2. Gera novo certificado
vault write -format=json pki_int/issue/agilarit-servers \
  common_name="rancher.agilarit.local" \
  alt_names="rancher.agilarit.com.br" \
  ip_sans="192.168.56.101" \
  ttl=8760h > rancher-cert-new.json

# 3. Extrai arquivos
cat rancher-cert-new.json | jq -r .data.certificate > rancher-new.crt
cat rancher-cert-new.json | jq -r .data.private_key > rancher-new.key
cat rancher-cert-new.json | jq -r .data.ca_chain[] > rancher-ca-new.crt

# 4. Atualiza no Rancher
kubectl create secret tls rancher-tls \
  --cert=rancher-new.crt \
  --key=rancher-new.key \
  -n cattle-system \
  --dry-run=client -o yaml | kubectl apply -f -

# 5. Reinicia Rancher
kubectl rollout restart deployment rancher -n cattle-system
```

### 10.4 Auditoria de Acesso

```bash
# Habilitar audit log
vault audit enable file file_path=/var/log/vault/audit.log

# Ver quem acessou secrets do SCI
cat /var/log/vault/audit.log | jq 'select(.request.path | contains("agilarit/sci"))'

# Ver todas as operações de um usuário
cat /var/log/vault/audit.log | jq 'select(.auth.display_name == "rafael")'

# Ver secrets acessados nas últimas 24h
cat /var/log/vault/audit.log | jq 'select(.time > (now - 86400))'
```

### 10.5 Backup e Disaster Recovery

```bash
# Snapshot do Vault (Raft storage)
vault operator raft snapshot save vault-backup-$(date +%Y%m%d).snap

# Restaurar snapshot
vault operator raft snapshot restore vault-backup-20260108.snap

# Backup de secrets específicos
vault kv get -format=json agilarit/sci/database > sci-db-backup.json

# Restaurar secret
vault kv put agilarit/sci/database @sci-db-backup.json
```

---

## Conclusão

Parabéns! Você completou o tutorial de Vault da AgilarIT. Agora você sabe:

✅ O que é Vault e por que usá-lo  
✅ Como gerenciar secrets estáticos (KV)  
✅ Como criar políticas de acesso granulares  
✅ Como implementar PKI completo  
✅ Como gerar credenciais dinâmicas de banco  
✅ Como integrar Vault com Kubernetes  
✅ Como usar criptografia como serviço (Transit)  
✅ Como aplicar Vault em cenários reais da AgilarIT  

## Próximos Passos

1. **Praticar**: Execute todos os comandos deste tutorial
2. **Experimentar**: Crie seus próprios secrets e políticas
3. **Integrar**: Implemente Vault em um projeto real
4. **Estudar**: Leia a documentação oficial para recursos avançados
5. **Automatizar**: Use Terraform para gerenciar configuração do Vault

## Recursos Adicionais

- [Documentação Oficial](https://www.vaultproject.io/docs)
- [Vault API Reference](https://www.vaultproject.io/api-docs)
- [Vault Tutorials](https://learn.hashicorp.com/vault)
- [Vault GitHub](https://github.com/hashicorp/vault)

---

**Criado para AgilarIT - 2026**  
**Autor**: Everton Agilar (DevOps)  
**Versão**: 1.0
