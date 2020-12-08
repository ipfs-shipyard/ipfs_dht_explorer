class AddLastLoadedAtToCids < ActiveRecord::Migration[6.0]
  def change
    add_column :cids, :last_loaded_at, :datetime
  end
end
