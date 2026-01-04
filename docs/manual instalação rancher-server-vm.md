# Guia de Instalação do Rancher Server (K3s + Vagrant VM)

Este manual descreve o procedimento para instalar o Rancher Server em uma Máquina Virtual Ubuntu utilizando Vagrant e K3s.

## 1. Criação da VM

Utilize o `Vagrantfile` configurado para subir a máquina.

```bash
vagrant up
# Para acessar a VM manualmente
vagrant ssh
```

> [!TIP]
> Você também pode utilizar o Ansible para automatizar toda a configuração após subir a VM.

> [!NOTE]
> Por padrão, o Vagrant cria a primeira interface (`eth0`) como NAT para acesso à internet. A segunda interface (`eth1`) é geralmente a rede privada/pública configurada no `Vagrantfile`.

## 2. Preparação do Sistema

Dentro da VM, atualize os pacotes e instale as dependências básicas.

```bash
sudo apt update && sudo apt install -y git curl iputils-ping iptables-persistent vim
```

**Via Ansible:**
```bash
ansible-playbook -i hosts.ini ansible/prepare-vm-playbook.yml
```

## 3. Instalação do K3s (Configuração de Rede)

Como a VM possui múltiplas interfaces, é crucial informar ao K3s qual IP e interface utilizar para evitar que ele utilize a rede NAT interna do Vagrant.

Considerando o IP `192.168.56.101` na interface `enp0s8`:

```bash
curl -sfL https://get.k3s.io | sh -s - \
  --node-ip=192.168.56.101 \
  --advertise-address=192.168.56.101 \
  --bind-address=192.168.56.101 \
  --flannel-iface=enp0s8 \
  --write-kubeconfig-mode=644 \
  --write-kubeconfig-group=rancher
```

**Via Ansible:**
```bash
ansible-playbook -i hosts.ini ansible/install-k3s-playbook.yml
```

### Verificação
```bash
sudo kubectl get nodes -o wide
```
A coluna `INTERNAL-IP` deve exibir `192.168.56.101`.

Exporte a variável para uso sem sudo (opcional):
```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config
```

## 4. Instalação do Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Via Ansible:**
```bash
ansible-playbook -i hosts.ini ansible/install-helm-playbook.yml
```

## 5. Instalação do Cert-Manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Instalar CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml

# Instalar via Helm
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0
```

**Via Ansible:**
```bash
ansible-playbook -i hosts.ini ansible/install-cert-manager-playbook.yml
```

## 6. Instalação do Rancher

Substitua `rancher.localhost` pelo hostname desejado se necessário.

```bash
# Criar namespace
kubectl create namespace cattle-system

# Adicionar repositório
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Instalação
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.arq.unb.br \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=rancher # ou secret se usar certs próprios
```

**Via Ansible:**
```bash
ansible-playbook -i hosts.ini ansible/install-rancher-playbook.yml
```

> [!NOTE]
> O playbook de instalação do Rancher também automatiza a criação do segredo TLS caso você forneça os arquivos de certificado.

## 7. Acesso ao Dashboard do Host

1.  **Edição do /etc/hosts**: No seu computador físico (fora da VM), mapeie o IP da VM ao hostname:
    ```text
    192.168.56.101 rancher.arq.unb.br
    ```

2.  **Acesso via Navegador**: Acesse [https://rancher.arq.unb.br](https://rancher.arq.unb.br).


