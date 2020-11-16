class AddMoreNodeIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :nodes, :updated_at
  end
end
