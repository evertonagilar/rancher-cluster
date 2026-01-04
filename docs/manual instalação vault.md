# Manual de Instalação e Configuração do HashiCorp Vault

Este documento detalha o processo de instalação do HashiCorp Vault utilizando Ansible e os passos manuais necessários para inicializar e desbloquear (unseal) o cofre.

## 1. Instalação Automatizada

A instalação é realizada através do playbook do Ansible `install-vault-playbook.yml`. Este playbook realiza as seguintes ações:
- Adiciona o repositório Helm da HashiCorp.
- Cria o namespace `vault`.
- Configura os certificados TLS (utilizando `arq.unb.br`).
- Instala o Vault Server (modo standalone).
- Instala o Vault Secrets Operator (VSO).

### Executando o Playbook

A partir da pasta `ansible` na raiz do projeto, execute:

```bash
ansible-playbook -i hosts.ini install-vault-playbook.yml
```

Aguarde a conclusão da execução. O Ansible irá configurar o Ingress para `vault.arq.unb.br`.

## 2. Inicialização e Unseal

Por razões de segurança, uma nova instalação do Vault inicia-se "selada" (sealed). Ela precisa ser inicializada para gerar as chaves de criptografia e, em seguida, as chaves devem ser fornecidas para "abrir" o cofre.

### Passo 1: Verificar o status dos Pods

Verifique se os pods do Vault estão rodando (embora o container `vault` possa não estar `Ready` ainda):

```bash
kubectl get pods -n vault
```

### Passo 2: Inicializar o Vault

Execute o comando de inicialização no pod `vault-0`. 

**ATENÇÃO:** Este comando irá gerar 5 chaves de unseal e 1 token root. **SALVE ESTES DADOS EM UM LOCAL SEGURO (ex: gerenciador de senhas).** Se você perder estas chaves, perderá o acesso aos dados do Vault permanentemente.

```bash
kubectl exec -ti vault-0 -n vault -- vault operator init
```

A saída será parecida com esta:
```text
Unseal Key 1: t7J...
Unseal Key 2: 8sL...
Unseal Key 3: 9kP...
Unseal Key 4: 2mX...
Unseal Key 5: 5nB...

Initial Root Token: hvs.7...
```

### Passo 3: Realizar o Unseal

O Vault requer um número mínimo de chaves (default: 3) para ser desbloqueado. Execute o comando abaixo 3 vezes, fornecendo uma chave **diferente** a cada vez.

```bash
kubectl exec -ti vault-0 -n vault -- vault operator unseal
```
*Cole a chave quando solicitado.*

Repita para a segunda chave:
```bash
kubectl exec -ti vault-0 -n vault -- vault operator unseal
```

Repita para a terceira chave:
```bash
kubectl exec -ti vault-0 -n vault -- vault operator unseal
```

Após a terceira chave válida, o status do Vault mudará para `Sealed: false`.

## 3. Acesso ao Vault

### Interface Web (UI)

Acesse o endereço configurado no Ingress:
https://vault.arq.unb.br

- **Method:** Token
- **Token:** Utilize o `Initial Root Token` gerado no passo de inicialização.

### Integração com Kubernetes (Vault Secrets Operator)

A role já instala o Vault Secrets Operator. Para que ele funcione, você precisará configurar a autenticação, o que geralmente envolve:
1. Habilitar o método de auth Kubernetes no Vault.
2. Configurar a role de acesso no Vault.
3. Criar os recursos `VaultConnection` e `VaultAuth` no cluster.

*Esta configuração de autenticação pós-instalação não é feita automaticamente pelo Ansible no momento e deve ser configurada via scripts ou Terraform conforme a política de segurança.*
