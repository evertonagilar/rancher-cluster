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

## 📂 Estrutura do Projeto

```text
.
├── ansible/
│   ├── roles/                 # Roles modulares
│   │   ├── cert_manager_install
│   │   ├── docker_install
│   │   ├── helm_install
│   │   ├── k3s_install
│   │   ├── prepare_vm
│   │   ├── rancher_install
│   │   ├── setup_hosts
│   │   ├── setup_kubeconfig
│   │   ├── setup_kubectl_autocomplete
│   │   └── setup_users
│   └── *.yml                  # Playbooks principais
├── docs/                      # Manuais de instalação detalhados
├── Vagrantfile                # Configuração da VM
├── hosts.ini                  # Inventário do Ansible
└── README.md                  # Este arquivo
```

## 🛠 Pré-requisitos

- **Vagrant** instalado.
- **VirtualBox** (ou outro provedor suportado).
- **Ansible** instalado na máquina host.

## 🚀 Como utilizar

1. **Subir a Máquina Virtual:**
   ```bash
   vagrant up
   ```

2. **Preparar a VM:**
   ```bash
   ansible-playbook -i hosts.ini ansible/prepare-vm-playbook.yml
   ```

3. **Instalar Docker e Dependências:**
   ```bash
   ansible-playbook -i hosts.ini ansible/install-docker-playbook.yml
   ```

4. **Instalar K3s e Helm:**
   ```bash
   ansible-playbook -i hosts.ini ansible/install-k3s-playbook.yml
   ansible-playbook -i hosts.ini ansible/install-helm-playbook.yml
   ```

5. **Instalar Cert-Manager e Rancher:**
   ```bash
   ansible-playbook -i hosts.ini ansible/install-cert-manager-playbook.yml
   ansible-playbook -i hosts.ini ansible/install-rancher-playbook.yml
   ```

6. **Configurar Acesso (Opcional):**
   ```bash
   # Configura usuários, kubeconfig e autocomplete
   ansible-playbook -i hosts.ini ansible/setup-users-playbook.yml
   ansible-playbook -i hosts.ini ansible/setup-kubeconfig-playbook.yml
   ansible-playbook -i hosts.ini ansible/setup-kubectl-autocomplete-playbook.yml

   # Adiciona entrada DNS no /etc/hosts (Remoto e Local)
   # Nota: Pode solicitar sua senha sudo local para o localhost
   ansible-playbook -i hosts.ini ansible/setup-hosts-playbook.yml --ask-become-pass
   ```

---

## 📖 Documentação Detalhada

Para guias passo-a-passo detalhados, consulte a pasta `docs/`:
- [Manual para VM (Vagrant)](docs/manual%20instala%C3%A7%C3%A3o%20rancher-server-vm.md)
- [Manual para Container (Docker)](docs/manual%20instala%C3%A7%C3%A3o%20rancher-server-docker.md -- Em desenvolvimento)

