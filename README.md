# Datacenter POC - Infrastructure as Code

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"/>
  <img src="https://img.shields.io/badge/Rancher-0075A8?style=for-the-badge&logo=rancher&logoColor=white" alt="Rancher"/>
  <img src="https://img.shields.io/badge/Vault-000000?style=for-the-badge&logo=vault&logoColor=white" alt="Vault"/>
  <img src="https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white" alt="Ansible"/>
  <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"/>
  <img src="https://img.shields.io/badge/Vagrant-1868F2?style=for-the-badge&logo=vagrant&logoColor=white" alt="Vagrant"/>
  <img src="https://img.shields.io/badge/VirtualBox-183A61?style=for-the-badge&logo=virtualbox&logoColor=white" alt="VirtualBox"/>
  <img src="https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm"/>
  <img src="https://img.shields.io/badge/GitOps-FC6D26?style=for-the-badge&logo=git&logoColor=white" alt="GitOps"/>
</p>

## Visão Geral

Este projeto é uma **Prova de Conceito (POC)** de um datacenter completo implementado com **Infrastructure as Code (IaC)** e práticas **GitOps**. O objetivo é demonstrar a automação completa de provisionamento, configuração e gerenciamento de uma infraestrutura empresarial moderna, incluindo:

- **Gerenciamento de Clusters Kubernetes** (Rancher)
- **Gerenciamento de Segredos** (HashiCorp Vault)
- **Autenticação Centralizada** (OpenLDAP)
- **Clusters de Produção** (RKE2)
- **GitOps e CI/CD** (ArgoCD - planejado)

Toda a infraestrutura é provisionada automaticamente usando **Vagrant** para VMs, **Ansible** para configuração, e **Helm** para aplicações Kubernetes, mantendo o estado desejado versionado em Git.

## Arquitetura da POC

```
┌─────────────────────────────────────────────────────────────┐
│                     Datacenter POC                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Rancher    │  │    Vault     │  │   OpenLDAP   │     │
│  │  Management  │  │   Secrets    │  │     Auth     │     │
│  │   Cluster    │  │  Management  │  │   Service    │     │
│  │    (K3s)     │  │    (K3s)     │  │    (K3s)     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                       │
│  │     RKE2     │  │    ArgoCD    │                       │
│  │  Production  │  │    GitOps    │                       │
│  │   Cluster    │  │   (Planned)  │                       │
│  └──────────────┘  └──────────────┘                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Componentes da Infraestrutura

### 🎯 `/rancher` - Management Plane
**Cluster de gerenciamento Rancher**
- Orquestra e gerencia todos os clusters Kubernetes
- Interface web para administração centralizada
- Baseado em K3s (leve e eficiente)

### 🔐 `/vault` - Secrets Management
**Servidor HashiCorp Vault**
- Gerenciamento centralizado de segredos e credenciais
- Integração com Kubernetes via Vault Secrets Operator
- Suporte a múltiplos backends de autenticação

### 👥 `/openldap` - Authentication Service
**Servidor OpenLDAP**
- Autenticação centralizada LDAP/LDAPS
- Estrutura organizacional simulando empresa de TI
- Usuários e grupos pré-configurados
- Integração com Rancher, Vault e ArgoCD

### 🚀 `/rke2` - Production Cluster
**Cluster RKE2 para workloads de produção**
- Cluster Kubernetes enterprise-grade
- Importado e gerenciado pelo Rancher
- Otimizado para cargas de trabalho críticas

### 📦 `/ansible` - Automation Layer
**Roles e playbooks Ansible**
- Automação modular e reutilizável
- Roles para cada componente da infraestrutura
- Preparação de VMs, instalação de software, configuração

### 📚 `/docs` - Documentation
**Documentação técnica e manuais**
- Guias de instalação manual
- Arquitetura e design decisions
- Troubleshooting e operação

## Requisitos

### Opção 1: Vagrant + VirtualBox (Recomendado para iniciantes)

- **VirtualBox** - Virtualização
- **Vagrant** - Provisionamento de VMs
- **Ansible** - Automação de configuração
- **Helm** - Gerenciamento de aplicações Kubernetes

### Opção 2: Terraform + Libvirt (Recomendado para produção)

- **Libvirt/KVM** - Virtualização nativa Linux
- **Terraform** - Infrastructure as Code
- **Ansible** - Automação de configuração
- **Helm** - Gerenciamento de aplicações Kubernetes

## Início Rápido

### Opção A: Usando Vagrant (VirtualBox)

#### 1. Provisionar Rancher (Management Cluster)

```bash
cd rancher
vagrant up
ansible-playbook -i hosts.ini install-playbook.yml
```

#### 2. Provisionar Vault (Secrets Management)

```bash
cd vault
vagrant up
ansible-playbook -i hosts.ini install-playbook.yml
```

#### 3. Provisionar OpenLDAP (Authentication)

```bash
cd openldap
vagrant up
ansible-playbook -i hosts.ini install-playbook.yml
```

#### 4. Provisionar RKE2 (Production Cluster)

```bash
cd rke2
vagrant up
ansible-playbook -i hosts.ini install-playbook.yml
```

### Opção B: Usando Terraform (Libvirt)

#### 1. Provisionar TODA a Infraestrutura

```bash
cd terraform/environments/local
terraform init
terraform apply
```

#### 2. Configurar com Ansible

```bash
cd ../../../ansible
ansible-playbook -i inventory/terraform.ini install-rancher-playbook.yml
ansible-playbook -i inventory/terraform.ini install-vault-playbook.yml
ansible-playbook -i inventory/terraform.ini install-openldap-playbook.yml
```

> **Nota**: Com Terraform, você pode provisionar tudo de uma vez ou componentes individuais usando `-target`. Veja [terraform/README.md](terraform/README.md) para mais detalhes.

## Acessando os Serviços

### Rancher
```bash
cd rancher
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
# Acesse via navegador usando o IP ou domínio configurado
```

### Vault
```bash
cd vault
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
# Acesse via navegador usando o IP ou domínio configurado
```

### OpenLDAP
```bash
# Testar conectividade LDAP (ajuste o domínio conforme configurado)
ldapsearch -x -H ldaps://<ldap-hostname> -b "<base-dn>" \
  -D "cn=admin,<base-dn>" -W
```

### RKE2
```bash
cd rke2
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

---

<p align="center">
  <sub>Em desenvolvimento por <strong>Everton de Vargas Agilar</strong></sub>
  <br>
  <sub>© 2024-2026</sub>
</p>
