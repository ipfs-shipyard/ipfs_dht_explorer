class CreateEdges < ActiveRecord::Migration[6.0]
  def change
    create_table :edges do |t|
      t.integer :source_id
      t.integer :target_id
      t.boolean :reachable

      t.timestamps
    end
  end
end
