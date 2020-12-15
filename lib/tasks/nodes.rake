namespace :nodes do
  task discover: :environment do
    Node.discover_connected_peers
  end

  task export: :environment do
    start_date = 7.days.ago
    end_date = Time.now
    path = '/data/ipfs/nodes.csv'
    Node.export(path, start_date, end_date)
  end

  task outdated_cids: :environment do
    versions = Node.only_go_ipfs.outdated.group(:agent_version).order('count_all desc').count.first(50)

    versions.each do |version, _count|
      scope = Node.where(agent_version: version).not_pl
      wants = Want.where(node_id: scope.pluck(:id)).group(:cid_id).order('count_all desc').count.first(500)

      wants.each do |cid_id, _count|
        DetectContentTypeWorker.perform_async(cid_id)
      end
    end
  end
end
