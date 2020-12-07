class DiscoverConnectedPeersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    Node.discover_connected_peers
  end
end
