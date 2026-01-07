# HashiCorp Vault Cluster em K3S 🔐

Este projeto automatiza a criação e configuração de um cluster Kubernetes (K3s) e a instalação do HashiCorp Vault, utilizando uma arquitetura modular baseada em **Ansible Roles**.

![Ansible](https://img.shields.io/badge/ansible-%23EE0000.svg?style=for-the-badge&logo=ansible&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![K3s](https://img.shields.io/badge/K3s-FFC107?style=for-the-badge&logo=kubernetes&logoColor=white)
![Vault](https://img.shields.io/badge/vault-%23000000.svg?style=for-the-badge&logo=vault&logoColor=white)
![Vagrant](https://img.shields.io/badge/vagrant-%231563FF.svg?style=for-the-badge&logo=vagrant&logoColor=white)
![Helm](https://img.shields.io/badge/helm-%230F1689.svg?style=for-the-badge&logo=helm&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E94331?style=for-the-badge&logo=ubuntu&logoColor=white)

---

## 📋 Sumário
- [Arquitetura](#-arquitetura)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Pré-requisitos](#-pré-requisitos)
- [Como utilizar](#-como-utilizar)
- [Documentação Detalhada](#-documentação-detalhada)

---

## 🏗 Arquitetura

O projeto foi transformado de playbooks lineares para uma estrutura de **Roles**, permitindo modularidade e fácil manutenção. 

O HashiCorp Vault é uma ferramenta para gerenciar segredos e proteger dados sensíveis. Ele fornece uma interface unificada para qualquer segredo, enquanto fornece controle de acesso rigoroso e registra um log de auditoria detalhado.

## 🛠 Pré-requisitos

- **Vagrant** instalado.
- **VirtualBox** (ou outro provedor suportado).
- **Ansible** instalado na máquina host.

## 🚀 Como utilizar

### Opção 1: Instalação Automatizada (Recomendado)

1. **Subir a Máquina Virtual:**
   ```bash
   vagrant up
   ```

2. **Executar o playbook consolidado:**
   ```bash
   ansible-playbook -i hosts.ini install-playbook.yml
   ```

   Este playbook executa automaticamente todos os passos necessários:
   - Preparação das VMs (usuários, pacotes, kernel, etc.)
   - Instalação do Docker
   - Instalação do K3s e Helm
   - Instalação do HashiCorp Vault
   - Configuração do kubeconfig e autocomplete
   - **Cópia automática do kubeconfig para o host local** em `~/.kube/rancher-cluster-vault.yaml`

3. **Acessar o cluster localmente:**
   ```bash
   # Usar o kubeconfig copiado automaticamente
   export KUBECONFIG=~/.kube/rancher-cluster-vault.yaml
   kubectl get nodes
   ```

4. **Verificar a instalação do Vault:**
   ```bash
   # Verificar os pods do Vault
   kubectl get pods -n vault
   
   # Verificar o serviço do Vault
   kubectl get svc -n vault
   ```

5. **Configuração opcional:**
   ```bash
   # Adiciona entrada DNS no /etc/hosts (Remoto e Local)
   # Nota: Pode solicitar sua senha sudo local para o localhost
   ansible-playbook -i hosts.ini ../ansible/setup-hosts-playbook.yml --ask-become-pass
   ```

---

### Opção 2: Instalação Passo a Passo

1. **Subir a Máquina Virtual:**
   ```bash
   vagrant up
   ```

2. **Preparar as VMs:**

Execute os playbooks de preparação básica do sistema:

   ```bash
   ansible-playbook -i hosts.ini ../ansible/create-local-users-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/install-common-software-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/disable-swap-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/config-sysctl-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/load-kernel-modules-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/install-chrony-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/locale-timezone-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/config-vim-playbook.yml
   ```

3. **Instalar Docker e Dependências:**
   ```bash
   ansible-playbook -i hosts.ini ../ansible/install-docker-playbook.yml
   ```

4. **Instalar K3s e Helm:**
   ```bash
   ansible-playbook -i hosts.ini ../ansible/install-helm-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/install-k3s-playbook.yml
   ```

5. **Instalar HashiCorp Vault:**
   ```bash
   ansible-playbook -i hosts.ini ../ansible/install-vault-playbook.yml
   ```

6. **Configuração opcional:**
   ```bash
   # Configura usuários, kubeconfig e autocomplete
   ansible-playbook -i hosts.ini ../ansible/setup-kubeconfig-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/setup-kubectl-autocomplete-playbook.yml

   # Adiciona entrada DNS no /etc/hosts (Remoto e Local)
   # Nota: Pode solicitar sua senha sudo local para o localhost
   ansible-playbook -i hosts.ini ../ansible/setup-hosts-playbook.yml --ask-become-pass
   ```

---

## 🔐 Inicialização e Unsealing do Vault

Após a instalação, o Vault precisa ser inicializado e "unsealed" (desbloqueado):

1. **Acessar a VM:**
   ```bash
   vagrant ssh vault-server
   ```

2. **Configurar o ambiente:**
   ```bash
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
   ```

3. **Verificar o status do Vault:**
   ```bash
   kubectl exec -n vault vault-0 -- vault status
   ```

4. **Inicializar o Vault (apenas na primeira vez):**
   ```bash
   kubectl exec -n vault vault-0 -- vault operator init
   ```

   > ⚠️ **IMPORTANTE**: Salve as chaves de unseal e o root token em um local seguro!

5. **Unseal do Vault:**
   ```bash
   # Execute 3 vezes com chaves diferentes
   kubectl exec -n vault vault-0 -- vault operator unseal <UNSEAL_KEY_1>
   kubectl exec -n vault vault-0 -- vault operator unseal <UNSEAL_KEY_2>
   kubectl exec -n vault vault-0 -- vault operator unseal <UNSEAL_KEY_3>
   ```

6. **Fazer login no Vault:**
   ```bash
   kubectl exec -n vault vault-0 -- vault login <ROOT_TOKEN>
   ```

---

## 🌐 Acessando a UI do Vault

O Vault possui uma interface web que pode ser acessada:

1. **Via Port-Forward:**
   ```bash
   kubectl port-forward -n vault svc/vault 8200:8200
   ```

   Acesse: `http://localhost:8200`

2. **Via NodePort ou LoadBalancer:**
   
   Verifique o tipo de serviço configurado:
   ```bash
   kubectl get svc -n vault
   ```

---

## 📖 Documentação Detalhada

Para guias passo-a-passo com instalação manual, consulte a pasta `docs/`:
- [Troubleshooting Vault](../docs/troubleshooting-vault.md) (se disponível)

---

## 🔧 Acesso ao Cluster

### Via SSH na VM

```bash
# Acessar o servidor
vagrant ssh vault-server
```

### Via kubectl Local

O kubeconfig é automaticamente copiado para `~/.kube/rancher-cluster-vault.yaml` durante a instalação.

```bash
# Usar o kubeconfig
export KUBECONFIG=~/.kube/rancher-cluster-vault.yaml
kubectl get nodes
kubectl get pods -n vault
```

---

## 🗑️ Limpeza

Para destruir o cluster e a VM:

```bash
vagrant destroy -f
```

---

## 📚 Recursos Adicionais

- [Documentação Oficial do Vault](https://www.vaultproject.io/docs)
- [Vault on Kubernetes](https://www.vaultproject.io/docs/platform/k8s)
- [Helm Chart do Vault](https://github.com/hashicorp/vault-helm)
