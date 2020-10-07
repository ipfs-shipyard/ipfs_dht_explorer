class AddLocationFieldsToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :country_iso_code, :string
    add_column :nodes, :country_name, :string
    add_column :nodes, :most_specific_subdivision_name, :string
    add_column :nodes, :city_name, :string
    add_column :nodes, :postal_code, :string
    add_column :nodes, :accuracy_radius, :integer
    add_column :nodes, :latitude, :float
    add_column :nodes, :longitude, :float
    add_column :nodes, :network, :string
  end
end
