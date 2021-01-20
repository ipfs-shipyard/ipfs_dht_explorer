class WantGcWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    Want.gc
  end
end
