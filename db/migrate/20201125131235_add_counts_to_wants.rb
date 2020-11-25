class AddCountsToWants < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :wants_count, :integer, default: 0
    add_column :cids, :wants_count, :integer, default: 0
  end
end
