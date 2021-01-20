class AddGatewayToNodes < ActiveRecord::Migration[6.1]
  def change
    add_column :nodes, :gateway, :boolean, default: false
  end
end
