# Projeto Rancher GitOps

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"/>
  <img src="https://img.shields.io/badge/Rancher-0075A8?style=for-the-badge&logo=rancher&logoColor=white" alt="Rancher"/>
  <img src="https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white" alt="Ansible"/>
  <img src="https://img.shields.io/badge/Vagrant-1868F2?style=for-the-badge&logo=vagrant&logoColor=white" alt="Vagrant"/>
  <img src="https://img.shields.io/badge/VirtualBox-183A61?style=for-the-badge&logo=virtualbox&logoColor=white" alt="VirtualBox"/>
  <img src="https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm"/>
  <img src="https://img.shields.io/badge/GitOps-FC6D26?style=for-the-badge&logo=git&logoColor=white" alt="GitOps"/>
</p>

Este projeto adota uma abordagem **GitOps** para provisionamento de infraestrutura Kubernetes. O objetivo é manter o estado desejado da infraestrutura versionado e automatizado.

## Requisitos
- Vagrant
- VirtualBox
- Ansible
- Helm

## Estrutura do Projeto

A organização das pastas reflete a separação de responsabilidades na infraestrutura:

### `/rancher` (Management Plane)
Contém o código e automação para provisionar o **Rancher Server**.
- Este é o "cluster de gerenciamento".
- Geralmente provisionado primeiro.
- Responsável por orquestrar e gerenciar outros clusters.
- Tecnologias: K3s, Rancher.

### `/rke2` (Downstream Clusters)
Contém o código e automação para provisionar clusters **RKE2**.
- Estes clusters são onde as aplicações de negócio rodam.
- Podem ser importados e gerenciados pelo Rancher Server.

### `/vault` (Secrets Management)
Contém o código e automação para provisionar o **HashiCorp Vault**.
- Cluster dedicado para gerenciamento de segredos.
- Baseado em K3s, leve e eficiente.
- Tecnologias: K3s, Vault.

### `/docs`
Contém documentação técnica e manuais operacionais.
- Manuais de instalação manual em vez de Ansible.
- Guias de arquitetura.

### `/ansible`
Roles e playbooks para auxiliar na automação da instalação e configuração dos componentes do projeto.

## Workflow de Provisionamento

```bash
# Para o cluster Rancher
cd rancher
ansible-playbook -i hosts.ini install-playbook.yml

# Para o cluster RKE2
cd rke2
ansible-playbook -i hosts.ini install-playbook.yml

# Para o cluster Vault
cd vault
ansible-playbook -i hosts.ini install-playbook.yml
```

### Usando o Kubeconfig

```bash
cd rancher
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

```bash
cd rke2
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

```bash
cd vault
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```
