class AddSightingsToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :sightings, :integer, default: 0
  end
end
