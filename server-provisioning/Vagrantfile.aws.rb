# -*- mode: ruby -*-
# vi: set ft=ruby :


CONFIG_VM_BOX = 'dummy'
INITIAL_SLEEP = '60'  # Delay allows networking to be fully available
SSH_USERNAME = 'ubuntu'

AWS_INSTANCE_TYPE  = "t1.micro"
AWS_TAGS           = {"Name" => "#{SERVER_TYPE} test #{ENV['USER']} #{Time.now.utc.to_s}"}
AWS_USER_DATA_FILE = "/tmp/user_data.txt"

# Note: use vagrant-aws plugin when testing instances on AWS
# https://github.com/mitchellh/vagrant-aws
# $ vagrant plugin install vagrant-aws
# $ vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
# $ vagrant up --provider=aws

if ARGV.include?('up')
  abort "Missing ICG_DOMAIN_PASSWORD"  if [nil, ''].include?(ENV['ICG_DOMAIN_PASSWORD'])
end

Vagrant.configure("2") do |config|

  config.vm.provider :aws do |aws, override|
    aws.access_key_id     = "YOUR ACCESS KEY"
    aws.secret_access_key = "YOUR SECRET ACCESS KEY"
    aws.keypair_name      = "YOUR KEYPAIR"
    aws.security_groups   = ["default"]
    override.ssh.private_key_path = "LOCAL PRIVATE KEY FILE"

    aws.ami               = AWS_BASE_AMI
    aws.instance_type     = AWS_INSTANCE_TYPE
    aws.tags              = AWS_TAGS
    aws.user_data         = File.read(AWS_USER_DATA_FILE) if File.exists?(AWS_USER_DATA_FILE)
    override.ssh.username = SSH_USERNAME
  end

end
