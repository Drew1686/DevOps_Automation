# -*- mode: ruby -*-
# vi: set ft=ruby :


#--------------------------------------
# Insight Catastrophe Group
ICG_DEFAULT_GATEWAY        = '172.19.110.1'
ICG_DOMAIN_ACCOUNT         = 'administrator'
ICG_FORWARD_ROOT_EMAILS_TO = 'devops@icg360.com'
ICG_MAIL_DOMAIN            = 'opd.com'
ICG_RELAYHOST              = 'randomtask.opd.com'
ICG_SUDO_USERS             = [ "ICS\\\\amunro_admin", "ICS\\\\dcassiero_admin", "ICS\\\\dtalati_admin", "ICS\\\\rchekaluk_admin", "ICS\\\\jruiz_admin", "ICS\\\\lbecker_admin" ]

#--------------------------------------
# Chef
CHEF_ARGUMENTS      = '--logfile /var/log/chef-solo.log'  # http://docs.opscode.com/ctl_chef_solo.html
CHEF_COOKBOOKS_PATH = "../cookbooks"

#--------------------------------------
# Destination location on VM of secret key file (for encrypted data items)
# https://groups.google.com/forum/#!topic/vagrant-up/MncNoFCttgg
# http://stackoverflow.com/a/25675579
ENCRYPTED_DATA_BAG_SECRET_KEY_FILE = "/tmp/vagrant-chef/encrypted_data_bag_secret_key"

#--------------------------------------
# Monitoring
ICINGA_HOST = '172.19.140.202'

#--------------------------------------
def abort(msg)
  puts msg
  exit 1
end

#--------------------------------------
def load_addtl_vagrant_file(env_var_name, default)
  additional_file_suffix = ENV[env_var_name].nil? || ENV[env_var_name] == '' ? default : ENV[env_var_name]

  begin
    require File.expand_path(File.dirname(__FILE__) + "/Vagrantfile.#{additional_file_suffix}")
  rescue
    puts "ERROR: File Vagrantfile.#{additional_file_suffix}.rb does not exist"
  end

  additional_file_suffix
end

#--------------------------------------
def is_virtualbox?
  begin
    IS_VIRTUALBOX == true
  rescue
    false
  end
end

#--------------------------------------
def icg_provision_linux_base(chef)
    chef.arguments      = CHEF_ARGUMENTS
    chef.cookbooks_path = CHEF_COOKBOOKS_PATH

    chef.encrypted_data_bag_secret_key_path = ENCRYPTED_DATA_BAG_SECRET_KEY_PATH if ENCRYPTED_DATA_BAG_SECRET_KEY_PATH.is_a?(String) && ::File.exists?(ENCRYPTED_DATA_BAG_SECRET_KEY_PATH)
    chef.data_bags_path = DATA_BAGS_PATH if DATA_BAGS_PATH.is_a?(String) && ::File.exists?(DATA_BAGS_PATH)

    chef.json = {
      :icg => {
        :domain => ICG_MAIL_DOMAIN,
        :icg_environment    => ICG_ENVIRONMENT,
        :join_account  => ICG_DOMAIN_ACCOUNT,
        :join_password => ENV['ICG_DOMAIN_PASSWORD'],
        :secret_key_file    => ENCRYPTED_DATA_BAG_SECRET_KEY_FILE,
      },
      'icinga-healthcheck' => {
        :enabled           => !is_virtualbox?,
        :icinga_password   => '7eket6sachAw',
        :icinga_user       => 'icinga_health_check',
        :mailto            => ICG_FORWARD_ROOT_EMAILS_TO,
        :period_in_hours   => 3,  # Increase as the number of servers increase (to eliminate excessive checking)
      },
      "ntp" => {
        "servers" => [
          "ntp.ubuntu.com",
          "pool.ntp.org"
        ]
      },
      "openssh" => {
        "server" => {
          "ClientAliveCountMax"  => "3",
          "ClientAliveInterval"  => "30",
          "GSSAPIAuthentication" => "no",
        }
      },
      :package_installer => {
        :packages => {
          'mailutils'                => nil,
          'rlwrap'                   => nil,
          'golang'                   => nil,
          'nagios-nrpe-server'       => nil,
          'nagios-plugins'           => nil,
          'nagios-plugins-basic'     => nil,
          'nagios-plugins-common'    => nil,
          'nagios-plugins-standard'  => nil,
          'sysstat'                  => nil,
        }
      },
      :pbis => {
        :version_major => '8.2',
        :version_minor => '8.2.0.2969',
      },
      :postfix => {
        :main => {
          'mydestination'              => '',
          'mydomain'                   => ICG_MAIL_DOMAIN,
          'myorigin'                   => '$myhostname',
          'relayhost'                  => ICG_RELAYHOST,
          'smtp_tls_CAfile'            => '',  # Default value causes: No such file or directory:/etc/postfix/cacert.pem
          'smtp_tls_mandatory_protocols'  => '!SSLv2,!SSLv3',
          'smtp_tls_protocols'            => '!SSLv2,!SSLv3',
          'smtpd_tls_mandatory_protocols' => '!SSLv2,!SSLv3',
          'smtpd_tls_protocols'           => '!SSLv2,!SSLv3',
        },
        :use_virtual_aliases => true,
        :virtual_aliases => {
          'root' => ICG_FORWARD_ROOT_EMAILS_TO,
        },
      },
      :resolvconf => {
        :nameserver => ['172.19.140.100', '172.19.141.200'],
        :search     => [ICG_MAIL_DOMAIN, 'ics.local'],
      },
      :system => {
        :timezone => 'UTC',
      },
      "authorization" => {
        "sudo" => {
            "include_sudoers_d" => true,
            "users" => ICG_SUDO_USERS,
            "passwordless" => false,
        }
      },
    }
	
    # Add a dummy instance_id when using Virtualbox
    begin
      chef.json.merge!(VIRTUALBOX_DUMMY_EC2_INSTANCE) unless VIRTUALBOX_DUMMY_EC2_INSTANCE.nil?
    rescue NameError => e
    end

    chef.add_recipe "apt"                                          # http://community.opscode.com/cookbooks/apt
    chef.add_recipe "package_installer"                            # http://community.opscode.com/cookbooks/package_installer
    #chef.add_recipe "gem_installer"                               # http://community.opscode.com/cookbooks/gem_installer
    chef.add_recipe "system"                                       # https://supermarket.getchef.com/cookbooks/system
    chef.add_recipe "ntp"                                          # http://community.opscode.com/cookbooks/ntp
    chef.add_recipe "openssh"                                      # https://github.com/opscode-cookbooks/openssh
    chef.add_recipe "fail2ban"                                     # https://github.com/opscode-cookbooks/fail2ban
    chef.add_recipe "postfix::server"                              # http://community.opscode.com/cookbooks/postfix
    chef.add_recipe "postfix::aliases"                             # http://community.opscode.com/cookbooks/postfix
    chef.add_recipe "zip"                                          # http://community.opscode.com/cookbooks/zip
    chef.add_recipe "icg-pbis"                                     # https://github.com/icg360/chef_cookbooks/tree/master/icg-pbis
    chef.add_recipe "icg-pbis::join_domain" unless is_virtualbox?
    chef.add_recipe "icg-icinga-healthcheck"                       # https://github.com/icg360/chef_cookbooks/tree/master/icg-icinga-healthcheck
    chef.add_recipe "ufw"                                          # https://supermarket.getchef.com/cookbooks/ufw
    chef.add_recipe "sudo"                                         # https://supermarket.getchef.com/cookbooks/sudo
    chef.add_recipe "python"                                       # https://supermarket.chef.io/cookbooks/python
    chef.add_recipe "logrotate"                                    # https://supermarket.chef.io/cookbooks/logrotate
end

#--------------------------------------
def icg_provision_linux_wrapup(config)

  $remove_ip_from_etc_hosts = <<REMOVE_IP_FROM_ETC_HOSTS
    ipaddr=`/sbin/ifconfig eth0 | grep inet.addr | awk '{print $2}' | awk -F: '{print $2}'`
    sudo sed -i "/^$ipaddr/d"   /etc/hosts
    sudo sed -i "/`hostname`/d" /etc/hosts
    sudo sed -i "/opd.com/d"    /etc/hosts
REMOVE_IP_FROM_ETC_HOSTS

  config.vm.provision "shell", {:inline => $remove_ip_from_etc_hosts}

  config.vm.provision "shell", {:inline => "rm -f ~#{SSH_USERNAME}/.ssh/authorized_keys"}
  config.vm.provision "shell", {:inline => "sudo passwd -l #{SSH_USERNAME}; sudo usermod --expiredate 1 #{SSH_USERNAME}"} if SSH_USERNAME == 'devops'

  config.vm.provision "shell", {:inline => "sudo reboot"} unless is_virtualbox?
end

#--------------------------------------
vm_env = load_addtl_vagrant_file('VM_ENVIRONMENT', 'virtualbox')  # VM_ENVIRONMENT selects virtual environment: virtualbox, existing, aws

# Not sure if there is any more robust way to detect a "vagrant up" command
# Inspired by https://groups.google.com/forum/#!topic/vagrant-up/XIxGdm78s4I
# Source code https://github.com/mitchellh/vagrant
if vm_env != 'existing'
  puts "\nProvisioning #{SERVER_TYPE} in #{vm_env}\n\n" if ARGV.include?('up')
else
  puts "\nLinking to existing server #{SERVER_TYPE}\n\n" if ARGV.include?('up')
end

#--------------------------------------
# Common Vagrant settings
Vagrant.configure("2") do |config|

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  config.omnibus.chef_version = :latest
  
  # The path to the Berksfile to use with Vagrant Berkshelf
  config.berkshelf.berksfile_path = "Berksfile"

  # Enabling the Berkshelf plugin. To enable this globally, add this configuration
  # option to your ~/.vagrant.d/Vagrantfile file
  config.berkshelf.enabled = true

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to exclusively install and copy to Vagrant's shelf.
  # config.berkshelf.only = []

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = CONFIG_VM_BOX

  #------------------------------------------------------
  # Get most current packages
  config.vm.provision "shell", {:inline => "sleep #{defined?(INITIAL_SLEEP) ? INITIAL_SLEEP : '0'}; sudo aptitude -y update; sudo aptitude -y safe-upgrade"}

end
