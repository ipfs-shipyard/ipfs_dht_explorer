class IpfsRepoGcWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    Node.ipfs_client.repo_gc
  end
end
