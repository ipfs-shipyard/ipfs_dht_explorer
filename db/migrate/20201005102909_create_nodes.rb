class CreateNodes < ActiveRecord::Migration[6.0]
  def change
    create_table :nodes do |t|
      t.string :node_id
      t.string :multiaddrs, array: true, default: []
      t.boolean :reachable
      t.string :agent_version

      t.timestamps
    end
  end
end
