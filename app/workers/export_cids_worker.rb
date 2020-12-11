class ExportCidsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    wants_count = 10
    path = '/data/ipfs/cids.csv'
    Cid.export(path, wants_count)
  end
end
