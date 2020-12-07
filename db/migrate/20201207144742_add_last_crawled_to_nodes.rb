class AddLastCrawledToNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :last_crawled, :datetime
  end
end
