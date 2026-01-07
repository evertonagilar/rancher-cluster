# Projeto Rancher GitOps

Este projeto adota uma abordagem **GitOps** para o gerenciamento de infraestrutura Kubernetes. O objetivo é manter o estado desejado da infraestrutura versionado e automatizado.

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

### `/docs`
Contém documentação técnica e manuais operacionais.
- Manuais de instalação manual em vez de Ansible.
- Guias de arquitetura.

### `/ansible`
Roles e playbooks para auxiliar na automação da instalação e configuração dos componentes do projeto.

## Workflow de Provisionamento

1.  **Bootstrap do Rancher**:
    - `cd rancher && vagrant up`
    - Provisiona o plano de controle central.
2.  **Provisionamento de Clusters**:
    - `cd rke2 && vagrant up`
    - Cria a infraestrutura física/VM para os clusters de aplicação.
    - Execução dos playbooks para instalar o RKE2.
3.  **Adoção (Import)**:
    - O cluster RKE2 é importado no dashboard do Rancher para gerenciamento centralizado (observabilidade, deploy de apps, RBAC).

