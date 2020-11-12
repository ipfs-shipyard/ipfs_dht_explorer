class CreateWants < ActiveRecord::Migration[6.0]
  def change
    create_table :wants do |t|
      t.integer :node_id
      t.integer :cid_id
      t.datetime :created_at, null: false
    end
    add_index :wants, :node_id
    add_index :wants, :cid_id
  end
end
