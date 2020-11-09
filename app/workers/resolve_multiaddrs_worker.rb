class ResolveMultiaddrsWorker
  include Sidekiq::Worker

  def perform(node_id)
    Node.find_by_id(node_id).try(:update_location_details)
  end
end
