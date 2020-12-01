class DetectContentTypeWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform(cid_id)
    Cid.find_by_id(cid_id).try(:detect_content_type)
  end
end
