# Terraform Infrastructure

Este diretório contém a infraestrutura como código (IaC) usando Terraform para provisionar o ambiente local com Libvirt/KVM.

## 📋 Pré-requisitos

### Instalar Libvirt e KVM

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager

# Habilitar e iniciar o serviço
sudo systemctl enable --now libvirtd

# Adicionar seu usuário ao grupo libvirt
sudo usermod -aG libvirt $USER
newgrp libvirt

# Verificar instalação
virsh list --all
```

### Instalar Terraform

```bash
# Baixar e instalar Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verificar instalação
terraform version
```

### Instalar Provider Libvirt

O provider será instalado automaticamente pelo Terraform durante o `terraform init`.

## 🚀 Uso Rápido

### 1. Provisionar Toda a Infraestrutura

```bash
cd terraform/environments/local

# Inicializar Terraform
terraform init

# Ver o que será criado
terraform plan

# Provisionar tudo
terraform apply
```

Isso criará:
- Rede virtual `k8s-network` (192.168.56.0/24)
- VM Rancher (192.168.56.101)
- VM Vault (192.168.56.102)
- VM OpenLDAP (192.168.56.100)
- Cluster RKE2 com 3 nodes (192.168.56.110-112)

### 2. Provisionar Componentes Específicos

```bash
# Apenas Rancher
terraform apply -target=module.rancher

# Apenas Vault
terraform apply -target=module.vault

# Apenas RKE2
terraform apply -target=module.rke2_cluster
```

### 3. Configurar com Ansible

Após o provisionamento, o Terraform gera automaticamente o inventory do Ansible:

```bash
cd ../../../ansible

# Verificar o inventory gerado
cat inventory/terraform.ini

# Executar playbooks
ansible-playbook -i inventory/terraform.ini install-rancher-playbook.yml
ansible-playbook -i inventory/terraform.ini install-vault-playbook.yml
ansible-playbook -i inventory/terraform.ini install-openldap-playbook.yml
```

### 4. Verificar Infraestrutura

```bash
# Ver outputs do Terraform
terraform output

# Ver resumo completo
terraform output infrastructure_summary

# Listar VMs no Libvirt
virsh list --all

# Ver detalhes de uma VM
virsh dominfo rancher-server

# Conectar via SSH
ssh vagrant@192.168.56.101
```

### 5. Destruir Infraestrutura

```bash
# Destruir tudo
terraform destroy

# Destruir componente específico
terraform destroy -target=module.rancher
```

## ⚙️ Configuração

### Personalizar Valores

Copie o arquivo de exemplo e edite conforme necessário:

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

Exemplo de customização:

```hcl
# terraform.tfvars

# Adicionar suas chaves SSH
ssh_public_keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@host"
]

# Ajustar recursos do Rancher
rancher_memory = 8192
rancher_vcpus  = 4

# Desabilitar componentes não necessários
enable_openldap = false
enable_rke2     = false

# Ajustar número de nodes RKE2
rke2_node_count = 5
```

### Habilitar/Desabilitar Componentes

Você pode controlar quais componentes serão provisionados:

```hcl
# terraform.tfvars
enable_rancher  = true   # Provisionar Rancher
enable_vault    = true   # Provisionar Vault
enable_openldap = false  # NÃO provisionar OpenLDAP
enable_rke2     = true   # Provisionar RKE2
```

## 📁 Estrutura

```
terraform/
├── environments/
│   └── local/                  # Ambiente local (Libvirt)
│       ├── main.tf             # Provider e backend
│       ├── variables.tf        # Variáveis de entrada
│       ├── network.tf          # Rede virtual
│       ├── rancher.tf          # VM Rancher
│       ├── vault.tf            # VM Vault
│       ├── openldap.tf         # VM OpenLDAP
│       ├── rke2.tf             # Cluster RKE2
│       ├── outputs.tf          # Outputs
│       ├── terraform.tfvars.example  # Exemplo de configuração
│       └── templates/
│           └── inventory.tpl   # Template do inventory Ansible
│
└── modules/
    ├── libvirt-vm/             # Módulo para VMs individuais
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── k8s-cluster/            # Módulo para clusters multi-node
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔄 Vagrant vs Terraform

Você pode escolher entre Vagrant (VirtualBox) ou Terraform (Libvirt):

| Aspecto | Vagrant + VirtualBox | Terraform + Libvirt |
|---------|---------------------|---------------------|
| **Performance** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Facilidade** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **State Management** | ❌ | ✅ |
| **Infraestrutura como Código** | Limitado | ✅ Completo |
| **Escalabilidade** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Migração para Cloud** | ❌ | ✅ Fácil |

### Workflow Vagrant

```bash
cd rancher
vagrant up
cd ../ansible
ansible-playbook -i ../rancher/hosts.ini install-rancher-playbook.yml
```

### Workflow Terraform

```bash
cd terraform/environments/local
terraform apply
cd ../../../ansible
ansible-playbook -i inventory/terraform.ini install-rancher-playbook.yml
```

## 🛠️ Troubleshooting

### Erro: "Failed to connect to libvirt"

```bash
# Verificar se o serviço está rodando
sudo systemctl status libvirtd

# Verificar permissões
groups | grep libvirt

# Se não estiver no grupo, adicionar e relogar
sudo usermod -aG libvirt $USER
newgrp libvirt
```

### Erro: "Error creating libvirt domain"

```bash
# Verificar pool de storage
virsh pool-list --all

# Se o pool default não existir, criar
virsh pool-define-as default dir --target /var/lib/libvirt/images
virsh pool-start default
virsh pool-autostart default
```

### Limpar Estado Corrompido

```bash
# Remover state e recriar
rm -rf .terraform terraform.tfstate*
terraform init
terraform apply
```

### VMs não iniciam

```bash
# Verificar logs do Libvirt
sudo journalctl -u libvirtd -f

# Verificar status da VM
virsh dominfo rancher-server

# Forçar inicialização
virsh start rancher-server
```

## 📚 Recursos

- [Terraform Libvirt Provider](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Libvirt Documentation](https://libvirt.org/docs.html)
- [KVM Documentation](https://www.linux-kvm.org/page/Documents)

## 🎯 Próximos Passos

Após provisionar a infraestrutura:

1. ✅ Verificar conectividade SSH com as VMs
2. ✅ Executar playbooks Ansible para configuração
3. ✅ Acessar os serviços (Rancher, Vault, etc.)
4. ✅ Importar clusters no Rancher
5. ✅ Configurar integração LDAP

---

**Dica**: Use `terraform plan` antes de `terraform apply` para ver exatamente o que será modificado!
