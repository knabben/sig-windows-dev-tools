# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

# Modify these in the variables.yaml file... they are described there in gory detail...
settingsFile = ENV["VAGRANT_VARIABLES"] || 'sync/shared/variables.yaml'
settings = YAML.load_file settingsFile

kubernetes_version=settings["kubernetes_version"]
k8s_linux_kubelet_nodeip=settings['k8s_linux_kubelet_nodeip']

linux_ram = settings['linux_ram']
linux_cpus = settings['linux_cpus']
windows_ram = settings['windows_ram']
windows_cpus = settings['windows_cpus']
windows_node_ip = settings['windows_node_ip']

cni = settings['cni']

Vagrant.configure(2) do |config|
  puts "cni:"
  puts cni

  # LINUX Control Plane
  config.vm.define :controlplane do |controlplane|
    controlplane.vm.host_name = "controlplane"
    controlplane.vm.box = "roboxes/ubuntu2004"

    controlplane.vm.network :private_network, ip:"#{k8s_linux_kubelet_nodeip}"
    controlplane.vm.provider :virtualbox do |vb|
    controlplane.vm.synced_folder "./sync/shared", "/var/sync/shared"
    controlplane.vm.synced_folder "./forked", "/var/sync/forked"
    controlplane.vm.synced_folder "./sync/linux", "/var/sync/linux"
      vb.memory = linux_ram
      vb.cpus = linux_cpus
    end

    ### This allows the node to default to the right IP i think....
    # 1) this seems to break the ability to get to the internet

    controlplane.vm.provision :shell, privileged: false, path: "sync/linux/controlplane.sh", args: "#{kubernetes_version} #{k8s_linux_kubelet_nodeip}"

    # TODO shoudl we pass KuberneteVersion to calico agent exe? and also service cidr if needed?
    # dont run as priveliged cuz we need the kubeconfig from regular user
    if cni == "calico" then
      controlplane.vm.provision "shell", path: "sync/linux/calico-0.sh"
    else
      controlplane.vm.provision "shell", path: "sync/linux/antrea-0.sh"
    end
  end

  # WINDOWS WORKER (win server 2019)
  config.vm.define :winw1 do |winw1|
    winw1.vm.host_name = "winw1"
    winw1.vm.box = "FriedrichWilken/Windows_2019-sig-win-dev-tools"

    winw1.vm.provider :virtualbox do |vb|
      vb.memory = windows_ram
      vb.cpus = windows_cpus
      vb.gui = false
    end

    winw1.vm.network :private_network, ip:"#{windows_node_ip}"
    winw1.vm.synced_folder ".", "/vagrant", disabled:true
    winw1.vm.synced_folder "./sync/shared", "C:/sync/shared"
    winw1.vm.synced_folder "./sync/windows/", "C:/sync/windows/"
    winw1.vm.synced_folder "./forked", "C:/forked/"

    winw1.winrm.username = "vagrant"
    winw1.winrm.password = "vagrant"
    winw1.winrm.timeout = 3600

    if not File.file?(".lock/joined") then
      # Joining the controlplane
      winw1.vm.provision "shell", path: "sync/windows/updates.ps1", privileged: true #, run: "never"
      winw1.vm.provision "shell", path: "sync/shared/kubejoin.ps1", privileged: true #, run: "never"
    else
      # TODO should we pass KuberneteVersion to calico agent exe? and also service cidr if needed?
      if not File.file?(".lock/cni") then
        if cni == "calico" then
          # installs both felix and node
          winw1.vm.provision "shell", path: "sync/windows/0-calico.ps1", privileged: true
          winw1.vm.provision "shell", path: "sync/windows/1-calico.ps1", privileged: true
        else
          winw1.vm.provision "shell", path: "sync/windows/0-antrea.ps1", privileged: true #, run: "always"
          winw1.vm.provision "shell", path: "sync/windows/1-antrea.ps1", privileged: true, args: "#{windows_node_ip}" #, run: "always"
        end
      end
    end
  end
end
