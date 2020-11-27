class ManualCrawlWorker
  include Sidekiq::Worker

  def perform(node_id)
    Node.find_by_id(node_id).try(:manual_crawl)
  end
end
