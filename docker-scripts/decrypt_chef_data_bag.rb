
require 'chef'
require 'chef/encrypted_data_bag_item'

# ruby ./decrypt_chef_data_bag.rb data_bags/mydata.json ~/Downloads/encrypted_data_bag_secret SPLUNK_ROOT_CERT

encrypted_data_path            = ARGV[0]
encrypted_data_bag_secret_path = ARGV[1]
data_bag_item                  = ARGV[2]

# Read secret key into a string
# http://www.bonusbits.com/main/HowTo:Encrypt_a_Data_Bag_to_use_with_Chef_Solo
secret = Chef::EncryptedDataBagItem.load_secret(encrypted_data_bag_secret_path)

# Read JSON encrypted data bag
json = File.open(encrypted_data_path) { |f| f.read }

# JSON to hash
# http://stackoverflow.com/a/7964378
data = JSON.parse(json)
#puts data.to_yaml

encrypted_data_bag = Chef::EncryptedDataBagItem.new(data, secret)
puts encrypted_data_bag[data_bag_item]

