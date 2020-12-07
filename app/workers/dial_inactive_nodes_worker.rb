class DialInactiveNodesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    Node.dial_inactive_nodes
  end
end
