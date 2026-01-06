# Troubleshooting Rancher

Este documento contém soluções para problemas comuns ao trabalhar com Rancher.

---

## Problema: Importação de Cluster Travada

### Sintomas

Ao importar um cluster K3s ou RKE2 no Rancher, o `cattle-cluster-agent` fica travado após conectar, apresentando o seguinte erro nos logs:

```bash
kubectl -n cattle-system logs -f cattle-cluster-agent-xxxxx
```

```
level=error msg="unable to read CA file from /etc/kubernetes/ssl/certs/serverca: no such file or directory"
```

O cluster permanece em estado "Pending" e nunca muda para "Active".

### Causa

O Rancher possui uma configuração global chamada `agent-tls-mode` que controla como os agents validam o certificado TLS do servidor Rancher. Quando configurado como **"strict"**, o agent espera encontrar um arquivo CA específico em `/etc/kubernetes/ssl/certs/serverca`, que não existe por padrão em clusters K3s/RKE2.

Além disso, o campo **`cacerts`** nas configurações do Rancher precisa estar populado com a cadeia de certificados CA (intermediate + root) para que os agents possam validar corretamente a cadeia de confiança do certificado TLS do Rancher.

### Solução 1: Configuração Automática via Ansible (Recomendado)

A role `rancher_install` já está configurada para:
- Definir automaticamente `agent-tls-mode: system-store`
- Configurar `cacerts` com a cadeia CA completa (intermediate + root)

Se você instalou o Rancher usando o playbook `install-rancher-playbook.yml`, essas configurações já devem estar aplicadas.

Para verificar:

```bash
# Verificar agent-tls-mode
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get setting agent-tls-mode -o yaml

# Verificar cacerts
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get setting cacerts -o yaml
```

### Solução 2: Alterar via Interface Web

1. Acesse o **Rancher Dashboard** (`https://rancher.arq.unb.br`)
2. Faça login como administrador
3. Clique no menu **☰** (canto superior esquerdo)
4. Vá em **Global Settings** → **Settings**
5. Procure pela configuração `agent-tls-mode`
6. Clique no ícone **⋮** (três pontos verticais) ao lado da configuração
7. Selecione **Edit Setting**
8. Altere o valor de `strict` para `system-store`
9. Clique em **Save**
10. Aguarde alguns minutos para o agent reconectar automaticamente

### Solução 2: Configuração Automática via Ansible

A role `rancher_install` já está configurada para definir automaticamente `agent-tls-mode: system-store` durante a instalação. Se você instalou o Rancher usando o playbook `install-rancher-playbook.yml`, essa configuração já deve estar aplicada.

Para verificar se a configuração foi aplicada:

```bash
# Via kubectl
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get setting agent-tls-mode -o yaml

# Ou via API
curl -k https://rancher.arq.unb.br/v3/settings/agent-tls-mode
```

### Solução 3: Usar Comando Insecure na Importação

Se você está usando certificados auto-assinados, use o comando de importação com `--insecure`:

```bash
curl --insecure -fL https://rancher.arq.unb.br/v3/import/xxxxx.yaml | kubectl apply -f -
```

### Entendendo os Modos de TLS

| Modo | Descrição | Quando Usar |
|------|-----------|-------------|
| `strict` | Requer CA específico em `/etc/kubernetes/ssl/certs/serverca` | Ambientes com PKI customizada |
| `system-store` | Usa CAs do sistema operacional | **Recomendado** - Funciona com CAs públicas e privadas instaladas no SO |
| `insecure` | Não valida certificados | ⚠️ Apenas para desenvolvimento/testes |

---

## Problema: Rancher não Inicia Após Instalação

### Sintomas

Os pods do Rancher ficam em estado `CrashLoopBackOff` ou `Error`.

### Diagnóstico

```bash
# Verificar status dos pods
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n cattle-system get pods

# Ver logs do Rancher
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n cattle-system logs -l app=rancher
```

### Possíveis Causas e Soluções

#### 1. Certificado TLS Inválido

Verifique se os certificados foram copiados corretamente para `ansible/roles/rancher_install/files/`:

```bash
ls -la ansible/roles/rancher_install/files/
```

Deve conter:
- `tls.crt` - Certificado do servidor
- `tls.key` - Chave privada
- `intermediate.pem` - Certificado intermediário
- `gs_root.pem` - Certificado raiz

#### 2. Secret TLS Não Criado

Verificar se o secret existe:

```bash
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n cattle-system get secret rancher-tls
```

Se não existir, reexecute a role:

```bash
ansible-playbook -i hosts.ini ../ansible/install-rancher-playbook.yml
```

#### 3. Recursos Insuficientes

O Rancher requer pelo menos:
- 4GB de RAM
- 2 CPUs

Verifique os recursos da VM no `Vagrantfile`.

---

## Problema: Não Consigo Acessar o Rancher Dashboard

### Sintomas

Ao acessar `https://rancher.arq.unb.br`, o navegador retorna erro de conexão ou timeout.

### Diagnóstico

```bash
# Verificar se o Rancher está rodando
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n cattle-system get pods -l app=rancher

# Verificar o serviço
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n cattle-system get svc rancher

# Verificar o ingress
kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n cattle-system get ingress
```

### Soluções

#### 1. Verificar /etc/hosts

Certifique-se de que `rancher.arq.unb.br` está mapeado para o IP correto:

```bash
# Na sua máquina local
cat /etc/hosts | grep rancher

# Deve conter:
192.168.56.101  rancher.arq.unb.br
```

Para adicionar automaticamente:

```bash
ansible-playbook -i hosts.ini ../ansible/setup-etc-hosts-playbook.yml --ask-become-pass
```

#### 2. Verificar Firewall

Certifique-se de que a porta 443 está acessível:

```bash
# Da sua máquina local
curl -k https://rancher.arq.unb.br/ping
```

#### 3. Aguardar Inicialização

O Rancher pode levar alguns minutos para inicializar completamente após a instalação. Aguarde até que todos os pods estejam em estado `Running`:

```bash
watch kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n cattle-system get pods
```

---

## Recursos Adicionais

- [Documentação Oficial do Rancher](https://ranchermanager.docs.rancher.com/)
- [Troubleshooting Guide Oficial](https://ranchermanager.docs.rancher.com/troubleshooting)
- [Rancher Forums](https://forums.rancher.com/)
