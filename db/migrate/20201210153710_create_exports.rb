class CreateExports < ActiveRecord::Migration[6.0]
  def change
    create_table :exports do |t|
      t.string :filename
      t.string :kind
      t.string :cid
      t.integer :size
      t.integer :records
      t.text :description

      t.timestamps
    end
  end
end
