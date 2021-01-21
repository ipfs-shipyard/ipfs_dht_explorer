class AddRandomPortToNodes < ActiveRecord::Migration[6.1]
  def change
    add_column :nodes, :random_port, :boolean, default: false
  end
end
