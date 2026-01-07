# Cluster RKE2 Downstream 🚀

Este projeto automatiza a criação e configuração de um cluster Kubernetes RKE2 (3 nós: 1 Server + 2 Agents) que será gerenciado pelo Rancher Server, utilizando uma arquitetura modular baseada em **Ansible Roles**.

![Ansible](https://img.shields.io/badge/ansible-%23EE0000.svg?style=for-the-badge&logo=ansible&logoColor=white)
![RKE2](https://img.shields.io/badge/RKE2-0075A8?style=for-the-badge&logo=kubernetes&logoColor=white)
![Rancher](https://img.shields.io/badge/rancher-%230075A1.svg?style=for-the-badge&logo=rancher&logoColor=white)
![Vagrant](https://img.shields.io/badge/vagrant-%231563FF.svg?style=for-the-badge&logo=vagrant&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E94331?style=for-the-badge&logo=ubuntu&logoColor=white)

---

## 📋 Sumário
- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Como utilizar](#-como-utilizar)
- [Importando no Rancher](#-importando-no-rancher)
- [Documentação Detalhada](#-documentação-detalhada)

---

## 🏗 Arquitetura

O projeto provisiona um cluster RKE2 com a seguinte topologia:

- **1 Server Node (Control Plane)**: `rke2-server` - 192.168.56.120 (4GB RAM, 2 CPUs)
- **2 Agent Nodes (Workers)**: 
  - `rke2-agent-1` - 192.168.56.121 (2GB RAM, 1 CPU)
  - `rke2-agent-2` - 192.168.56.122 (2GB RAM, 1 CPU)

O RKE2 é uma distribuição Kubernetes certificada pela CNCF focada em segurança e conformidade, ideal para ambientes de produção, edge e on-premise.

## 🛠 Pré-requisitos

- **Vagrant** instalado.
- **VirtualBox** (ou outro provedor suportado).
- **Ansible** instalado na máquina host.
- **Rancher Server** rodando (veja o diretório `../rancher`).

## 🚀 Como utilizar

### Opção 1: Instalação Automatizada (Recomendado)

1. **Subir as Máquinas Virtuais:**
   ```bash
   vagrant up
   ```

2. **Executar o playbook consolidado:**
   ```bash
   ansible-playbook -i hosts.ini install-playbook.yml
   ```

   Este playbook executa automaticamente todos os passos necessários:
   - Preparação das VMs (usuários, pacotes, kernel, etc.)
   - Instalação do RKE2 (Server + Agents)
   - Configuração do kubeconfig e autocomplete
   - **Cópia automática do kubeconfig para o host local** em `~/.kube/rancher-cluster-rke2.yaml`

3. **Acessar o cluster localmente:**
   ```bash
   # Usar o kubeconfig copiado automaticamente
   export KUBECONFIG=~/.kube/rancher-cluster-rke2.yaml
   kubectl get nodes
   ```

4. **Configuração opcional:**
   ```bash
   # Adiciona entrada DNS no /etc/hosts (Remoto e Local)
   # Nota: Pode solicitar sua senha sudo local para o localhost
   ansible-playbook -i hosts.ini ../ansible/setup-etc-hosts-playbook.yml --ask-become-pass
   ```

---

### Opção 2: Instalação Passo a Passo

1. **Subir as Máquinas Virtuais:**
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

3. **Instalar RKE2:**

Execute o playbook de instalação do RKE2:

   ```bash
   ansible-playbook -i hosts.ini ../ansible/install-rke2-playbook.yml
   ```

   Este playbook irá:
   - Instalar o RKE2 Server no nó master
   - Instalar os RKE2 Agents nos nós workers
   - Configurar automaticamente o token de autenticação
   - Criar links simbólicos para `kubectl` e `crictl`

4. **Configuração Opcional:**

   ```bash
   # Configura kubeconfig e autocomplete
   ansible-playbook -i hosts.ini ../ansible/setup-kubeconfig-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/setup-kubectl-autocomplete-playbook.yml

   # Adiciona entrada DNS no /etc/hosts (Remoto e Local)
   # Nota: Pode solicitar sua senha sudo local para o localhost
   ansible-playbook -i hosts.ini ../ansible/setup-etc-hosts-playbook.yml --ask-become-pass
   ```

---

## 🔗 Importando no Rancher

Após o cluster RKE2 estar rodando, você pode importá-lo no Rancher Server:

1. Acesse o **Rancher Dashboard** (ex: `https://rancher.arq.unb.br`)
2. Vá em **Cluster Management** → **Import Existing**
3. Selecione **Generic** como tipo de cluster
4. Dê um nome ao cluster (ex: `rke2-downstream`)
5. Copie o comando `kubectl apply` fornecido pelo Rancher
6. Execute o comando no **nó Server** do RKE2:

```bash
# SSH no server
vagrant ssh rke2-server

# Configure o KUBECONFIG
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

# Execute o comando fornecido pelo Rancher
curl --insecure -fL https://rancher.arq.unb.br/v3/import/... | kubectl apply -f -
```

7. Aguarde alguns instantes até o cluster aparecer como **Active** no Rancher

---

## 📖 Documentação Detalhada

Para guias passo-a-passo com instalação manual, consulte a pasta `docs/`:
- [Manual de Criação de Cluster RKE2](../docs/manual-criacao-cluster-rke2.md)

---

## 🔧 Acesso ao Cluster

### Via SSH nas VMs

```bash
# Acessar o server
vagrant ssh rke2-server

# Acessar os agents
vagrant ssh rke2-agent-1
vagrant ssh rke2-agent-2
```

### Via kubectl Local

Copie o kubeconfig do server para sua máquina local:

```bash
# Obter o kubeconfig
vagrant ssh rke2-server -c "sudo cat /etc/rancher/rke2/rke2.yaml" > ~/.kube/rke2-config

# Editar o arquivo e trocar 127.0.0.1 por 192.168.56.120
sed -i 's/127.0.0.1/192.168.56.120/g' ~/.kube/rke2-config

# Usar o kubeconfig
export KUBECONFIG=~/.kube/rke2-config
kubectl get nodes
```

---

## 🗑️ Limpeza

Para destruir o cluster e as VMs:

```bash
vagrant destroy -f
```
