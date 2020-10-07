class AddProtocolsToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :protocols, :string, array: true, default: []
  end
end
