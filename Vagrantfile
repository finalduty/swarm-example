# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  config.vm.define "proxy1" do |d|
    d.vm.box = "centos/7"
    d.vm.hostname = "proxy1"
    d.vm.network "private_network", ip: "10.0.0.11"
    d.vm.provision "shell", path: "bootstrap-proxy.sh"
  end  
  
  config.vm.define "node1" do |d|
    d.vm.box = "centos/7"
    d.vm.hostname = "node1"
    d.vm.network "private_network", ip: "10.0.0.21"
    d.vm.provision "shell", path: "bootstrap-node.sh"
  end
 
  config.vm.define "node2" do |d|
    d.vm.box = "centos/7"
    d.vm.hostname = "node2"
    d.vm.network "private_network", ip: "10.0.0.22"
    d.vm.provision "shell", path: "bootstrap-node.sh"
  end
 
  config.vm.define "node3" do |d|
    d.vm.box = "centos/7"
    d.vm.hostname = "node3"
    d.vm.network "private_network", ip: "10.0.0.23"
    d.vm.provision "shell", path: "bootstrap-node.sh"
  end
   
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    v.memory = 2048
    v.cpus = 2
  end

end
