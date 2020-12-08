class DetectContentTypesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    Cid.detect_content_types
  end
end
