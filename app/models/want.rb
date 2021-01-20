require 'csv'

class Want < ApplicationRecord
  belongs_to :node
  belongs_to :cid

  def self.export(path, start_date, end_date)
    scope = Want.where('created_at > ?', start_date).where('created_at < ?', end_date).includes(:cid, :node)
    CSV.open(path, "wb", row_sep: "\r\n") do |csv|
      csv << ['Peer ID', 'CID', 'time']
      scope.find_each(batch_size: 5000) do |want|
        csv << [want.node.node_id, want.cid.cid, want.created_at]
      end
    end
    filename = path.split('/').last
    folders = path.split('/')[0..-2].join('/')
    `cd #{folders} && tar -czf #{filename}.tar.gz #{filename}`
    archive_path = "#{folders}/#{filename}.tar.gz"
    records = scope.count
    resp = Node.ipfs_client.add(archive_path)
    Export.create(filename: resp['Name'],
                  kind: 'wants',
                  cid: resp['Hash'],
                  size: resp['Size'],
                  records: records,
                  description: "Wants seen between #{start_date.strftime('%b %d, %Y, %l:%M %p')} and #{end_date.strftime('%b %d, %Y, %l:%M %p')}")
    File.delete(path)
    File.delete(archive_path)
  end

  def self.gc
    Want.where('created_at < ?', 7.days.ago).delete_all
  end
end
