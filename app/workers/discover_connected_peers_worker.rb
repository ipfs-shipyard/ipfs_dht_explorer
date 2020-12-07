class DiscoverConnectedPeersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform(node_id)
    Node.discover_connected_peers
  end
end
