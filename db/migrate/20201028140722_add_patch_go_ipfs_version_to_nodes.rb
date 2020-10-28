class AddPatchGoIpfsVersionToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :patch_go_ipfs_version, :string
  end
end
