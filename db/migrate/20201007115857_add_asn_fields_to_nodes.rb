class AddAsnFieldsToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :autonomous_system_number, :integer
    add_column :nodes, :autonomous_system_organization, :string
  end
end
