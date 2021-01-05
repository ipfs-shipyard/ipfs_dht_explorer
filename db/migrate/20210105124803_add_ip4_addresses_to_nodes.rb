class AddIp4AddressesToNodes < ActiveRecord::Migration[6.1]
  def change
    add_column :nodes, :ip4_addresses, :string, array: true, default: []
  end
end
