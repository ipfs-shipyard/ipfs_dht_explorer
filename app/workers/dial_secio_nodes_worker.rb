class DialSecioNodesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    Node.dial_secio_nodes
  end
end
