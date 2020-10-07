require 'csv'

class Edge < ApplicationRecord
  has_many :source_peers, class_name: 'Node', primary_key: :target_id, foreign_key: :id
  has_many :target_peers, class_name: 'Node', primary_key: :source_id, foreign_key: :id

  def self.import_from_crawler
    # Edge.delete_all
    csv = CSV.read("/Users/andrewnesbitt/go/src/ipfs-crawler/output_data_crawls/peerGraph_05-10-20--10:42:16_05-10-20--10:46:52.csv", headers: true, col_sep: ";")
    nodes = Node.all.select('id, node_id').to_a
    h = {}
    nodes.each do |n|
      h[n.node_id] = n.id
    end
    csv.each do |row|
      source_id = h[row['SOURCE']]
      target_id = h[row['TARGET']]
      if source_id.present? && target_id.present?
        Edge.create(source_id: source_id, target_id: target_id, reachable: row['ONLINE'])
      end
    end
  end
end
