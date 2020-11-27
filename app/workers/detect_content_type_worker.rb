class DetectContentTypeWorker
  include Sidekiq::Worker

  def perform(cid_id)
    Cid.find_by_id(cid_id).try(:detect_content_type)
  end
end
