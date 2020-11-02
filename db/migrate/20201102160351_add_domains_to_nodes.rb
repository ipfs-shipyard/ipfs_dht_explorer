class AddDomainsToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :domains, :string, array: true, default: []
  end
end
