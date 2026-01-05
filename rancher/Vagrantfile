Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "rancher-server"
  config.vm.network "private_network", ip: "192.168.56.101"
  config.ssh.insert_key = false
  config.ssh.private_key_path = "~/.vagrant.d/insecure_private_key"
  config.ssh.verify_host_key = false

  config.vm.provider "virtualbox" do |vb|
     vb.memory = "4096"
     vb.cpus = 2
  end

end
