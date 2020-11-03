class AddNodeIdIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :nodes, :node_id, unique: true
  end
end
