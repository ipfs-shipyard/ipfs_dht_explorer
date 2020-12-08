class Cid < ApplicationRecord
  has_many :wants, dependent: :delete_all
  has_many :nodes, through: :wants

  IPFS_GATEWAY_HOST = "http://#{ENV.fetch("IPFS_URL") { '127.0.0.1' }}:#{ENV.fetch("IPFS_GATEWAY_PORT") { '8080' }}"

  def self.detect_content_types
    Cid.where(content_type: nil, last_loaded_at: nil).limit(1000).order('wants_count desc').pluck(:id).each{|id| DetectContentTypesWorker.perform_async(id) }
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
end
