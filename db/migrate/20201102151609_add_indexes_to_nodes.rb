class AddIndexesToNodes < ActiveRecord::Migration[6.0]
  def change
    add_index :nodes, :agent_version
    add_index :nodes, :minor_go_ipfs_version
    add_index :nodes, :country_iso_code
  end
end
