[rancher]
%{~ if length(rancher_ips) > 0 ~}
${rancher_ips[0]}
%{~ endif ~}

[vault]
%{~ if length(vault_ips) > 0 ~}
${vault_ips[0]}
%{~ endif ~}

[openldap]
%{~ if length(openldap_ips) > 0 ~}
${openldap_ips[0]}
%{~ endif ~}

[rke2]
%{~ for ip in rke2_ips ~}
${ip}
%{~ endfor ~}

[all:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
