class Cid < ApplicationRecord
  has_many :wants, dependent: :delete_all
  has_many :nodes, through: :wants

  IPFS_GATEWAY_HOST = "http://#{ENV.fetch("IPFS_URL") { '127.0.0.1' }}:#{ENV.fetch("IPFS_GATEWAY_PORT") { '8080' }}"

  def self.detect_content_types
    Cid.where(content_type: nil).limit(1000).order('id desc').each(&:detect_content_type)
  end

  def detect_content_type
    return if cid.blank?
    begin
      resp = HTTP.timeout(5).head("#{IPFS_GATEWAY_HOST}/ipfs/#{cid}")
      update(content_type: resp.headers["Content-Type"], content_length: resp.headers["Content-Length"])
    rescue HTTP::TimeoutError, HTTP::ConnectionError => e
      # failed to find
    end
  end
end
