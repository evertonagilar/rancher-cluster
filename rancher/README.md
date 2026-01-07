# Rancher Cluster em K3S 🚀

Este projeto automatiza a criação e configuração de um cluster Kubernetes (K3s) e a instalação do Rancher Server, utilizando uma arquitetura modular baseada em **Ansible Roles**.

![Ansible](https://img.shields.io/badge/ansible-%23EE0000.svg?style=for-the-badge&logo=ansible&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![K3s](https://img.shields.io/badge/K3s-FFC107?style=for-the-badge&logo=kubernetes&logoColor=white)
![Rancher](https://img.shields.io/badge/rancher-%230075A1.svg?style=for-the-badge&logo=rancher&logoColor=white)
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

2. **Configuração de Certificados TLS (Importante ⚠️):**
   
   Como os certificados não são versionados no Git, você precisa copiá-los manualmente para as pastas `files` das respectivas roles antes da execução.

   #### Rancher
   
   Copie os seguintes arquivos para `ansible/roles/rancher_install/files/`:
   
   ```
   ansible/roles/rancher_install/files/
   ├── cert.crt              # Certificado do servidor (ex: rancher.arq.unb.br)
   ├── key.key               # Chave privada do certificado
   ├── intermediate.pem      # Certificado intermediário da CA
   └── gs_root.pem          # Certificado raiz da CA (GlobalSign)
   ```
   
   > **Nota:** A role cria automaticamente uma cadeia completa de certificados (server → intermediate → root) para garantir a validação correta da cadeia de confiança.

3. **Executar o playbook consolidado:**
   ```bash
   ansible-playbook -i hosts.ini install-playbook.yml
   ```

   Este playbook executa automaticamente todos os passos necessários:
   - Preparação das VMs (usuários, pacotes, kernel, etc.)
   - Instalação do Docker
   - Instalação do K3s e Helm
   - Instalação do Cert-Manager
   - Instalação do Rancher Server
   - Configuração do kubeconfig e autocomplete
   - **Cópia automática do kubeconfig para o host local** em `~/.kube/rancher-cluster-rancher.yaml`

4. **Acessar o cluster localmente:**
   ```bash
   # Usar o kubeconfig copiado automaticamente
   export KUBECONFIG=~/.kube/rancher-cluster-rancher.yaml
   kubectl get nodes
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

2. **Configuração de Certificados TLS (Importante ⚠️):**
   
   Como os certificados não são versionados no Git, você precisa copiá-los manualmente para as pastas `files` das respectivas roles antes da execução.

   #### Rancher
   
   Copie os seguintes arquivos para `ansible/roles/rancher_install/files/`:
   
   ```
   ansible/roles/rancher_install/files/
   ├── cert.crt              # Certificado do servidor (ex: rancher.arq.unb.br)
   ├── key.key               # Chave privada do certificado
   ├── intermediate.pem      # Certificado intermediário da CA
   └── gs_root.pem          # Certificado raiz da CA (GlobalSign)
   ```
   
   > **Nota:** A role cria automaticamente uma cadeia completa de certificados (server → intermediate → root) para garantir a validação correta da cadeia de confiança.

3. **Preparar as VMs:**

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

4. **Instalar Docker e Dependências:**
   ```bash
   ansible-playbook -i hosts.ini ../ansible/install-docker-playbook.yml
   ```

5. **Instalar K3s e Helm:**
   ```bash
   ansible-playbook -i hosts.ini ../ansible/install-helm-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/install-k3s-playbook.yml
   ```

6. **Instalar Cert-Manager e Rancher:**
   ```bash
   ansible-playbook -i hosts.ini ../ansible/install-cert-manager-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/install-rancher-playbook.yml
   ```

7. **Configuração opcional:**
   ```bash
   # Configura usuários, kubeconfig e autocomplete
   ansible-playbook -i hosts.ini ../ansible/setup-kubeconfig-playbook.yml
   ansible-playbook -i hosts.ini ../ansible/setup-kubectl-autocomplete-playbook.yml

   # Adiciona entrada DNS no /etc/hosts (Remoto e Local)
   # Nota: Pode solicitar sua senha sudo local para o localhost
   ansible-playbook -i hosts.ini ../ansible/setup-hosts-playbook.yml --ask-become-pass
   ```

---

## 📖 Documentação Detalhada

Para guias passo-a-passo com instalação manual, consulte a pasta `docs/`:
- [Manual para VM (Vagrant)](docs/manual%20instala%C3%A7%C3%A3o%20rancher-server-vm.md)
- [Manual para Container (Docker)  -- Em desenvolvimento](docs/manual%20instala%C3%A7%C3%A3o%20rancher-server-docker.md)
- [Troubleshooting Rancher](../docs/troubleshooting-rancher.md)

