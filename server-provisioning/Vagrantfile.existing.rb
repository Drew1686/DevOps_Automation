# -*- mode: ruby -*-
# vi: set ft=ruby :


CONFIG_VM_BOX = "tknerr/managed-server-dummy"  # https://vagrantcloud.com/tknerr/boxes/managed-server-dummy
SSH_USERNAME = 'devops'

# Requires plugin vagrant-managed-servers
# $ vagrant plugin install vagrant-managed-servers
# https://github.com/tknerr/vagrant-managed-servers

# Usage:
#   envvars="VM_ENVIRONMENT=existing PRIVATE_KEY_PATH=$HOME/.ssh/id_rsa ENCRYPTED_DATA_BAG_SECRET_KEY_PATH=/tmp/secretfile.staginguat ICG_ENVIRONMENT=uat EXISTING_SERVER_NAME=rogue.opd.com ICG_DOMAIN_PASSWORD=insert-ad-password"
#   env $envvars vagrant up --provider=managed  # (links Vagrant to the existing server)
#   env $envvars vagrant provision              # (runs provisioners)
#   env $envvars vagrant ssh -- -o GSSAPIAuthentication=no  # (shell onto the existing server)
#   env $envvars vagrant destroy                # (unlinks Vagrant to the existing server)

if ARGV.include?('up') || ARGV.include?('provision')
  abort "Missing PRIVATE_KEY_PATH"     if [nil, ''].include?(ENV['PRIVATE_KEY_PATH'])
  abort "Missing EXISTING_SERVER_NAME" if [nil, ''].include?(ENV['EXISTING_SERVER_NAME'])
  abort "Missing ICG_DOMAIN_PASSWORD"  if [nil, ''].include?(ENV['ICG_DOMAIN_PASSWORD'])

  abort "PRIVATE_KEY_PATH #{ENV['PRIVATE_KEY_PATH']} does not exist" unless ::File.exists?(ENV['PRIVATE_KEY_PATH'])
end

Vagrant.configure("2") do |config|
  config.vm.provider :managed do |managed, override|
    managed.server                = ENV['EXISTING_SERVER_NAME']
    override.ssh.username         = SSH_USERNAME
    override.ssh.private_key_path = ENV['PRIVATE_KEY_PATH']

  end
end

