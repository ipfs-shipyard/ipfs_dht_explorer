class AddWantsCountIndexToCids < ActiveRecord::Migration[6.0]
  def change
    add_index :cids, :wants_count
  end
end
