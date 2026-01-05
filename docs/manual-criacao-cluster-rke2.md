# Manual de Criação de Cluster Kubernetes com RKE2

Este manual descreve o procedimento para provisionar um cluster Kubernetes utilizando o RKE2 (Rancher Kubernetes Engine 2) via CLI e posteriormente importá-lo para o Rancher.

## Introdução

O RKE2 é uma distribuição Kubernetes certificada pela CNCF que foca em segurança e conformidade. Ele combina o melhor do RKE1 (facilidade de uso) e do K3s (leveza e empacotamento), sendo ideal para ambientes de produção, edge e on-premise.

## Por que usar o utilitário RKE2 (CLI) vs Provisionamento via Rancher Dashboard?

Embora o Rancher Dashboard permita provisionar clusters diretamente em provedores de nuvem ou via RKE1/RKE2 em nós existentes, existem benefícios significativos em desacoplar o ciclo de vida do cluster do gerenciamento do Rancher:

1.  **Independência do Plano de Gerenciamento**: Se o servidor Rancher ficar indisponível, você ainda mantém controle total sobre o cluster RKE2 via CLI (`kubectl`, `rke2`) e SSH.
2.  **Segurança e Conformidade**: O RKE2 é focado em segurança (suporte a FIPS, SELinux, CIS Benchmarks). Instalá-lo manualmente permite ajustes finos no S.O. antes do cluster subir.
3.  **GitOps & Automação**: O processo de instalação do RKE2 é facilmente automatizável via Ansible, Terraform ou User Data, tornando a infraestrutura como código (IaC) mais robusta do que depender da API do Rancher para provisionamento.
4.  **Menor Overhead no Rancher**: Importar um cluster consome menos recursos do servidor Rancher do que gerenciar todo o ciclo de vida de provisionamento (especialmente em grandes escalas).
5.  **Ambientes Air-Gapped**: O RKE2 possui um método de instalação offline muito robusto, facilitando o deploy em ambientes sem internet direta, o que é mais complexo de orquestrar apenas pelo Dashboard.

---

## Pré-requisitos

*   **Sistema Operacional**: Linux (Ubuntu 20.04/22.04, RHEL 8/9, Rocky Linux, etc).
*   **Recursos (Mínimo recomendado)**:
    *   2 CPU
    *   4 GB RAM
*   **Rede**:
    *   IP Fixo configurado nos nós.
    *   Hostname único configurado (`sudo hostnamectl set-hostname <nome-do-no>`).
    *   Acesso à internet (ou binários pré-baixados para air-gap).

## Passo 1: Instalação do Primeiro Nó (Server/Master)

Execute os passos abaixo no servidor que será o control-plane.

1.  **Instalar o RKE2**:
    ```bash
    curl -sfL https://get.rke2.io | sh -
    ```

2.  **Habilitar e Iniciar o Serviço**:
    ```bash
    systemctl enable rke2-server.service
    systemctl start rke2-server.service
    ```

3.  **(Opcional) Instalar o binário kubectl no PATH**:
    O RKE2 traz seus próprios binários em `/var/lib/rancher/rke2/bin`. Você pode criar links simbólicos ou adicionar ao path.
    ```bash
    ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
    ln -s /var/lib/rancher/rke2/bin/crictl /usr/local/bin/crictl
    ```

4.  **Configurar o Kubeconfig**:
    Para acessar o cluster com o usuário root:
    ```bash
    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    kubectl get nodes
    ```
    *Dica: Copie este arquivo para `~/.kube/config` na sua máquina local para acesso remoto.*

5.  **Obter o Token de Registro**:
    Você precisará deste token para adicionar outros nós (workers ou masters adicionais).
    ```bash
    cat /var/lib/rancher/rke2/server/node-token
    ```

## Passo 2: Adicionando Nós (Agentes/Workers)

Nos servidores que serão os workers:

1.  **Definir Variáveis de Ambiente**:
    Substitua pelos valores do seu servidor master.
    ```bash
    export RKE2_URL=https://<IP-DO-SERVER-MASTER>:9345
    export RKE2_TOKEN=<CONTEUDO-DO-NODE-TOKEN>
    ```

2.  **Instalar o RKE2 Agent**:
    Note que aqui o tipo de configuração é `rke2-agent`.
    ```bash
    curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
    ```

3.  **Habilitar e Iniciar**:
    ```bash
    systemctl enable rke2-agent.service
    systemctl start rke2-agent.service
    ```

## Passo 3: Importando o Cluster no Rancher

Com o cluster rodando, siga estes passos para importá-lo na interface do Rancher:

1.  Faça login no Rancher Dashboard.
2.  Clique no menu hamburger (canto superior esquerdo) e vá em **"Cluster Management"**.
3.  Clique em **"Import Cluster"**.
4.  Selecione **"Generic"**.
5.  Dê um nome ao cluster (ex: `meu-cluster-rke2`) e clique em **"Create"**.
6.  O Rancher exibirá um comando `kubectl apply ...`. Copie o comando apropriado (geralmente o segundo, que ignora verificação de certificado se você não tiver certificados públicos válidos no Rancher, ou o primeiro se tiver).
7.  Execute o comando **no nó Server** (Master) do seu cluster RKE2:
    ```bash
    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    # Cole o comando do Rancher aqui, por exemplo:
    curl --insecure -fL https://<seu-rancher>/v3/import/... | kubectl apply -f -
    ```
8.  Aguarde alguns instantes. O status no Rancher mudará de "Pending" para "Active".

---

## Dicas Adicionais

*   **Configuração via Arquivo**: Em vez de variáveis de ambiente, você pode criar o arquivo `/etc/rancher/rke2/config.yaml` antes da instalação.
    *   Exemplo para Server:
        ```yaml
        token: meu-segredo-super-seguro
        tls-san:
          - meu-cluster.dominio.com
        ```
    *   Exemplo para Agent:
        ```yaml
        server: https://<IP-MASTER>:9345
        token: meu-segredo-super-seguro
        ```
*   **Desisntalação**:
    *   Server: `rke2-killall.sh` seguido de `rke2-uninstall.sh`
    *   Agent: `rke2-killall.sh` seguido de `rke2-uninstall.sh`
