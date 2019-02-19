# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  config.vm.box = "sbeliakou/centos-7.3-x86_64-minimal"
  config.vm.define "serv" do |server|
  	server.vm.network "private_network", ip: "192.168.56.2"
    server.vm.provision "shell" ,path:"server.sh"
	end	

config.vm.define "agent" do |agent|
  agent.vm.network "private_network", ip: "192.168.56.3"
  agent.vm.provision "shell" ,path:"agent.sh"
  agent.vm.provision "shell" ,path:"add-host.sh",args: "agent1"

	end	

 
end
