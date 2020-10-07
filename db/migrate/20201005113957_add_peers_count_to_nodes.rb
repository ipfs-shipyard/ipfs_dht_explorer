class AddPeersCountToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :peers_count, :integer, default: 0
  end
end
