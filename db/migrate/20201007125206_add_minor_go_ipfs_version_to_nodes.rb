class AddMinorGoIpfsVersionToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :minor_go_ipfs_version, :string
  end
end
