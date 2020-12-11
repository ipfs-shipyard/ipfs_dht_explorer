class ExportWantsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    start_date = 1.day.ago
    end_date = Time.now
    path = '/data/ipfs/wants.csv'
    Want.export(path, start_date, end_date)
  end
end
