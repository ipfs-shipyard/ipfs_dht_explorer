require 'csv'

class Cid < ApplicationRecord
  has_many :wants, dependent: :delete_all
  has_many :nodes, through: :wants

  IPFS_GATEWAY_HOST = "http://#{ENV.fetch("IPFS_URL") { '127.0.0.1' }}:#{ENV.fetch("IPFS_GATEWAY_PORT") { '8080' }}"

  def self.detect_content_types
    Cid.where(content_type: nil, last_loaded_at: nil).limit(1000).order('wants_count desc').pluck(:id).each{|id| DetectContentTypeWorker.perform_async(id) }
  end

  def detect_content_type
    return if cid.blank?
    begin
      resp = HTTP.timeout(1).head("#{IPFS_GATEWAY_HOST}/ipfs/#{cid}")
      update(content_type: resp.headers["Content-Type"], content_length: resp.headers["Content-Length"], last_loaded_at: Time.now)
    rescue HTTP::TimeoutError, HTTP::ConnectionError => e
      # failed to find
      update_column(:last_loaded_at, Time.now)
    end
  end

  def self.export(path, wants_count)
    scope = Cid.where('wants_count > ?', wants_count)
    CSV.open(path, "wb", row_sep: "\r\n") do |csv|
      csv << Cid.attribute_names
      scope.find_each(batch_size: 5000) do |cid|
        csv << cid.attributes.values
      end
    end
    filename = path.split('/').last
    folders = path.split('/')[0..-2].join('/')
    `cd #{folders} && tar -czf #{filename}.tar.gz #{filename}`
    archive_path = "#{folders}/#{filename}.tar.gz"
    records = scope.count
    resp = Node.ipfs_client.add(archive_path)
    Export.create(filename: resp['Name'],
                  kind: 'cids',
                  cid: resp['Hash'],
                  size: resp['Size'],
                  records: records,
                  description: "CIDs with more than #{wants_count} want requests")
    File.delete(path)
    File.delete(archive_path)
  end
end
