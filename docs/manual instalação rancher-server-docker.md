# Guia de Instalação do Rancher Server (K3s + Docker)

Este manual descreve o procedimento para instalar o Rancher Server em um ambiente profissional, utilizando um container Ubuntu com suporte a `systemd` para simular uma VM, rodando K3s.

## 1. Criação do Container

Utilizaremos uma imagem preparada para suporte a `systemd`. Para simular uma VM real e evitar conflitos de portas no seu host, acessaremos o container diretamente pelo seu IP interno na rede do Docker.

```bash
# 1. Criar o container
docker run --name=rancher-server --rm -it --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v k3s-data:/var/lib/rancher/k3s \
  --cgroupns=host \
  antmelekhin/docker-systemd:ubuntu-22.04
```

# 2. Obter o IP do Cluster (Execute no seu PC/Host)
Logo após iniciar o container, capture o IP dele para facilitar a configuração do acesso ao final:

```bash
export CLUSTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' rancher-server)
echo "O IP do seu cluster é: $CLUSTER_IP"
```

## 2. Preparação do Sistema

Dentro do container, atualize os pacotes e instale as dependências básicas.

```bash
apt update && apt install -y git curl iputils-ping iptables-persistent vim
```

**Via Ansible (se SSH estiver ativo):**
```bash
ansible-playbook -i hosts.ini ansible/prepare-vm-playbook.yml
```

> **Nota:** Este playbook utiliza a role `common_software` para instalar pacotes essenciais.

## 3. Instalação do K3s

Instale o K3s configurando-o para uso interno.

```bash
# Capturar o IP interno automaticamente (dentro do container)
CLUSTER_IP=$(hostname -I | awk '{print $1}')

# Instalação com parâmetros idênticos ao Ansible para evitar problemas de rota
curl -sfL https://get.k3s.io | sh -s - \
  --node-ip=$CLUSTER_IP \
  --advertise-address=$CLUSTER_IP \
  --bind-address=$CLUSTER_IP \
  --write-kubeconfig-group=rancher \
  --write-kubeconfig-mode=644 \
  --flannel-iface=eth0

kubectl get nodes
```

**Via Ansible:**
```bash
ansible-playbook -i hosts.ini ansible/install-k3s-playbook.yml
```

Exporte a variável de ambiente para o kubectl e helm

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

## 4. Instalação do Helm

O Helm é o gerenciador de pacotes necessário para instalar o Rancher.

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 5. Instalação do Cert-Manager

O Rancher utiliza o `cert-manager` para gerenciar certificados TLS.

```bash
# Adicionar repositório Jetstack Helm
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Instalar CustomResourceDefinitions (CRDs)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml

# Instalar cert-manager via Helm
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0
```

**Via Ansible:**
```bash
ansible-playbook -i hosts.ini ansible/install-cert-manager-playbook.yml
```

Verifique se os pods estão rodando:
```bash
kubectl get pods --namespace cert-manager
```

## 6. Instalação e Provisionamento do Rancher

Agora, instale o Rancher utilizando o Helm.

```bash
# Adicionar repositório Rancher
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Instalar Rancher
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=rancher.arq.unb.br \
  --set bootstrapPassword=admin
```

**Via Ansible:**
```bash
ansible-playbook -i hosts.ini ansible/install-rancher-playbook.yml
```

## 7. Verificação Final

Acompanhe o deploy do Rancher:

```bash
kubectl -n cattle-system rollout status deploy/rancher
```

## 8. Acesso ao Dashboard

Para acessar o Rancher do seu computador (Host) utilizando o IP do container (simulando uma VM externa), siga estes passos:

1.  **Edição do /etc/hosts**: No seu PC, adicione a linha mapeando a variável `$CLUSTER_IP` ao hostname:
    ```bash
    echo "$CLUSTER_IP rancher.arq.unb.br" | sudo tee -a /etc/hosts
    ```

2.  **Acesso via Navegador**: Acesse [https://rancher.arq.unb.br](https://rancher.arq.unb.br).

