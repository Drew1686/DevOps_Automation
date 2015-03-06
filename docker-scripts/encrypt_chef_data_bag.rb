
# From http://www.bonusbits.com/main/HowTo:Encrypt_a_Data_Bag_to_use_with_Chef_Solo
require 'rubygems'
require 'chef/encrypted_data_bag_item'

# ruby ./encrypt_chef_data_bag.rb ~/Downloads/encrypted_data_bag_secret [<file containing cleartext>]

encrypted_data_bag_secret_path = ARGV[0]
optional_file_of_cleartext     = ARGV[1]

secret = Chef::EncryptedDataBagItem.load_secret(encrypted_data_bag_secret_path)

filestr = File.open(optional_file_of_cleartext) { |f| f.read } if !optional_file_of_cleartext.nil? && optional_file_of_cleartext != ''
data = {'ITEM_NAME1' => filestr.nil? ? 'cleartext value to encrypt' : filestr}
encrypted_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(data, secret)
puts encrypted_data.to_json

puts "\n"
data = {'ITEM_NAME2' => 'cleartext value to encrypt'}
encrypted_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(data, secret)
puts encrypted_data.to_json

