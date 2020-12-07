class DialIncompleteNodesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform
    Node.dial_incomplete_nodes
  end
end
