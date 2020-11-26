class AddContentTypeToCids < ActiveRecord::Migration[6.0]
  def change
    add_column :cids, :content_type, :string
    add_column :cids, :content_length, :bigint
  end
end
