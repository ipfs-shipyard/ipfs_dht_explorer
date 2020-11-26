class AddPlToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :pl, :boolean, default: false
  end
end
