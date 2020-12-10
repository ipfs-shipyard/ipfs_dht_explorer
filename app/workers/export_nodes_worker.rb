class ExportNodesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    start_date = 7.days.ago
    end_date = Time.now
    path = '/data/ipfs/nodes.csv'
    Node.export(path, start_date, end_date)
  end
end
