class CreateCids < ActiveRecord::Migration[6.0]
  def change
    create_table :cids do |t|
      t.string :cid
    end
    add_index :cids, :cid, unique: true
  end
end
