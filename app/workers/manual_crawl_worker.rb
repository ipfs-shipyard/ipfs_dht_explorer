class ManualCrawlWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform(node_id)
    Node.find_by_id(node_id).try(:manual_crawl)
  end
end
