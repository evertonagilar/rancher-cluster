# Cluster RKE2 Downstream

Este diretório contém a automação para provisionar um cluster Kubernetes RKE2 que será gerenciado pelo Rancher.

## Estrutura
- `Vagrantfile`: Define 3 VMs (1 Server, 2 Agents).
- `ansible/`: Contém playbooks para instalação do RKE2.

## Como Usar

1.  **Subir as VMs**:
    ```bash
    vagrant up
    ```

2.  **Provisionar com Ansible**:
    ```bash
    cd ansible # vá para a raiz de ansible do projeto se necessário
    ansible-playbook -i ../rke2/ansible/inventory/hosts.ini ../ansible/install-rke2-playbook.yml
    ```

3.  **Acesso**:
    - O cluster estará acessível no nó Server (192.168.56.120).
    - O kubeconfig fica em `/etc/rancher/rke2/rke2.yaml` no master.

## Importando no Rancher
Siga as instruções em `../docs/manual-criacao-cluster-rke2.md` para importar este cluster no Rancher Server rodando no diretório irmão `../rancher`.
