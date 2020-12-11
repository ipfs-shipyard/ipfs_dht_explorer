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
end
