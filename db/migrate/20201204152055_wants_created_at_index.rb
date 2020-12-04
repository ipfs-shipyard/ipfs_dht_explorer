class WantsCreatedAtIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :wants, :created_at
  end
end
