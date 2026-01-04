# Guia de Instalação do Rancher Server (K3s + Systemd Container)

Este manual descreve o procedimento para instalar o Rancher Server em um ambiente profissional, utilizando um container Ubuntu com suporte a `systemd` para simular uma VM, rodando K3s.

## 1. Criação do Container

Utilizaremos uma imagem preparada para suporte a `systemd`. Para simular uma VM real e evitar conflitos de portas no seu host, acessaremos o container diretamente pelo seu IP interno na rede do Docker.

```bash
docker run --name=rancher-server --rm -it --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v k3s-data:/var/lib/rancher/k3s \
  --cgroupns=host \
  antmelekhin/docker-systemd:ubuntu-22.04
```

## 2. Preparação do Sistema

Dentro do container, atualize os pacotes e instale as dependências básicas.

```bash
apt update && apt install -y git curl iputils-ping iptables-persistent vim
```

## 3. Instalação do K3s

Instale o K3s configurando-o para uso interno.

```bash
curl -sfL https://get.k3s.io | sh -
kubectl get nodes
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
# Substitua 'rancher.seu-dominio.com' pelo seu hostname ou IP
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=rancher.localhost \
  --set bootstrapPassword=admin
```

## 7. Verificação Final

Acompanhe o deploy do Rancher:

```bash
kubectl -n cattle-system rollout status deploy/rancher
```

## 8. Acesso ao Dashboard

Para acessar o Rancher do seu computador (Host) utilizando o IP do container (simulando uma VM externa), siga estes passos:

1.  **Descubra o IP do Container**: No terminal do seu PC (fora do container), execute:
    ```bash
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' rancher-server
    ```
    *Suponhamos que o IP retornado seja `172.17.0.2`.*

2.  **Edição do /etc/hosts**: No seu PC, adicione a linha mapeando o IP ao hostname configurado no Rancher (`rancher.localhost`):
    ```text
    172.17.0.2 rancher.localhost
    ```

3.  **Acesso via Navegador**: Acesse [https://rancher.localhost](https://rancher.localhost).

### Por que isto é necessário?

*   **Ingress e o Cabeçalho Host**: O K3s utiliza o Traefik como Ingress Controller. Quando você instalou o Rancher, definimos `--set hostname=rancher.localhost`. O Traefik usa esse nome para saber que o tráfego HTTP/HTTPS deve ser enviado para o pod do Rancher. Se você tentar acessar pelo IP direto (`https://172.17.0.2`), o Traefik não saberá para onde rotear a requisição.
*   **Conectividade L3 vs L7**: O `ping` funciona porque o Linux roteia pacotes para a interface do Docker (Camada 3). O acesso ao dashboard (Camada 7) exige que o nome do host corresponda ao que o Ingress espera.
## 9. Conceitos de Rede: LoadBalancer no K3s

Uma dúvida comum em instalações Kubernetes Bare Metal é sobre o uso de soluções como **MetalLB**. No caso do K3s, você **não precisa do MetalLB** para este laboratório.

### O que é o ServiceLB (Klipper)?
O K3s já vem com um controlador de LoadBalancer embutido chamado **ServiceLB** (também conhecido como Klipper).
*   **Como funciona**: Quando você cria um Service do tipo `LoadBalancer` (como o do Traefik Ingress), o ServiceLB cria pods em cada nó que escutam nas portas configuradas (ex: 80 e 443) e encaminham o tráfego para os pods reais da aplicação.
*   **Diferença para o MetalLB**: O MetalLB é uma solução muito mais robusta (usa BGP ou ARP) para ambientes de produção complexos. O ServiceLB é simplificado e ideal para K3s rodando em máquinas únicas ou containers, pois ele apenas faz o "bind" da porta diretamente na interface de rede da máquina (ou container).

### Por que o Rancher depende dele?
O Rancher é exposto via **Ingress Controller** (Traefik). O Traefik, por sua vez, é exposto via um Service do tipo `LoadBalancer`. É o ServiceLB que garante que, ao acessar o IP do seu container na porta 443, você chegue ao Traefik, que então olha o cabeçalho `Host` para te levar ao Rancher.

### Comparativo de Métodos de Acesso

| Método | Persistência | Porta | Recomendação |
| :--- | :--- | :--- | :--- |
| **LoadBalancer (ServiceLB)** | Permanente | 80/443 | O ideal "profissional". Simula uma Cloud/VM real. |
| **NodePort** | Permanente | 30000-32767 | Mais estável em ambientes Docker problemáticos, mas usa portas altas (ex: 30443). |
| **Port-Forward** | Temporário | Qualquer | Excelente para troubleshooting ou laboratórios rápidos. |

**O NodePort é melhor?**
No Kubernetes, o **NodePort** é considerado um método mais "bruto" e confiável de expor serviços porque ele não depende de um controlador de LoadBalancer externo (ou do ServiceLB do K3s) para rotear o tráfego de fora para dentro. No entanto, ele geralmente obriga o uso de portas fora do padrão (30000-32767). Para um laboratório que busca simular uma VM real, o **LoadBalancer** (porta 443) é esteticamente superior, mas o **NodePort** é uma alternativa técnica muito sólida se você não se importar com a porta na URL.

## 10. Solução de Problemas: Porta 443 Não Abre

Se você consegue pingar o container, mas o comando `ss -tln` dentro dele não mostra a porta 443 aberta, o K3s não conseguiu expor o Traefik. Isso geralmente acontece porque o **ServiceLB** (Klipper) do K3s falhou ao tentar "bindar" a porta no IP do container.

### 1. Verifique o Status do Serviço Traefik
Execute dentro do container:
```bash
kubectl get svc -n kube-system traefik
```
**O que observar**: A coluna `EXTERNAL-IP` deve mostrar o IP do seu container (ex: `172.17.0.2`). Se estiver como `<pending>`, o Ingress não está exposto para fora.

### 2. Verifique os Pods do ServiceLB
O K3s cria pods especiais para fazer o encaminhamento de porta. Verifique se eles estão rodando:
```bash
kubectl get pods -n kube-system | grep svclb-traefik
```
Se eles estiverem em `CrashLoopBackOff` ou `Error`, verifique os logs:
```bash
kubectl logs -n kube-system -l app=svclb-traefik
```

### 3. Possíveis Causas e Correções

*   **Iptables no Container**: O ServiceLB depende do `iptables` dentro do container. Certifique-se de que o pacote `iptables` está instalado e que você rodou o container com `--privileged`.
    ```bash
    apt install -y iptables
    ```
*   **Conflito de Portas Interno**: Certifique-se de que nenhum outro processo dentro do container está usando a porta 80 ou 443 antes do K3s subir.
*   **Aguarde o Rancher**: Às vezes, o Ingress do Rancher só é ativado após todos os pods do namespace `cattle-system` estarem `Running`.
    ```bash
    kubectl get pods -n cattle-system
    ```

### 11. Expondo a Porta Manualmente no Manifesto (HostPort)

Sua ideia de editar o manifesto é tecnicamente correta: você está falando de usar um **hostPort** ou **hostNetwork**. Isso obrigaria o Traefik a "sequestrar" a porta 443 da interface do container.

**O desafio no K3s**:
O Traefik no K3s é gerenciado por um controlador do Helm. Se você editar o pod ou o deployment manualmente (`kubectl edit`), o K3s eventualmente irá sobrescrever suas mudanças.

**A forma correta (Persistente)**:
Você pode configurar o Traefik criando um arquivo de configuração para o Helm do K3s.
1.  Crie o arquivo `/var/lib/rancher/k3s/server/manifests/traefik-config.yaml` dentro do container:
    ```yaml
    apiVersion: helm.cattle.io/v1
    kind: HelmChartConfig
    metadata:
      name: traefik
      namespace: kube-system
    spec:
      valuesContent: |-
        ports:
          websecure:
            expose: true
            hostPort: 443
    ```
2.  O K3s detectará a mudança e reiniciará o Traefik aplicando o `hostPort`.

**Isso é melhor?**
O `hostPort` é excelente porque é performático e permanente. No entanto, se o bind falhar (por exemplo, se algo já estiver usando a porta 443 ou devido a restrições de rede do Docker), o Traefik simplesmente não subirá. O `port-forward` sugerido anteriormente é mais "resiliente" para laboratórios porque não depende do sistema de arquivos do K3s estar pronto.

### Pro-Tip: Forçando o Acesso via Port-Forward

Se o ServiceLB falhar e você não quiser usar o `-p` do Docker, você pode "pontear" o serviço manualmente de dentro do container para a interface `eth0`. Isso garante que a porta 443 fique aberta no IP do container.

Execute dentro do container (pode deixar rodando em segundo plano ou em outro terminal):
```bash
# Encaminha o tráfego da porta 443 do container para o serviço do Rancher
kubectl port-forward -n cattle-system svc/rancher 443:443 --address 0.0.0.0 &
```

**Por que isso resolve?**
Diferente de uma VM real, o Docker tem camadas extras de isolamento de rede. O comando `port-forward` com `--address 0.0.0.0` obriga o Kubernetes a abrir a porta 443 em **todas** as interfaces internas do container, incluindo aquela que o seu PC consegue enxergar.

### Resumo do Fluxo de Acesso
1.  **Container**: Garante que o Rancher está rodando e a porta 443 está aberta (via ServiceLB ou Port-Forward).
2.  **Seu PC**: `ping IP_DO_CONTAINER` deve funcionar.
3.  **Seu PC**: `/etc/hosts` deve ter `IP_DO_CONTAINER rancher.localhost`.
4.  **Browser**: Acesse `https://rancher.localhost`.