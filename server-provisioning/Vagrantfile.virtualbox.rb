# -*- mode: ruby -*-
# vi: set ft=ruby :


CONFIG_VM_BOX = VIRTUALBOX_BASE_BOX
SSH_USERNAME = 'vagrant'

IS_VIRTUALBOX = true

VIRTUALBOX_DUMMY_EC2_INSTANCE = {
  "ec2" => {
    "instance_id" => "#{ENV['USER']}_virtualbox"
  }
}

VIRTUALBOX_SWAP_FILE = ''

Vagrant.configure("2") do |config|

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "http://domain.com/path/to/above.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network :private_network, ip: "192.168.33.2"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider :virtualbox do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  # Optionally disable vbguest installs
  # Can circumvent issue "Temporary failure resolving 'us.archive.ubuntu.com'"
  # caused by vagrant-vbguest attempting to install guest additions
  # http://kvz.io/blog/2013/01/16/vagrant-tip-keep-virtualbox-guest-additions-in-sync/
  #config.vbguest.no_install = true

end
