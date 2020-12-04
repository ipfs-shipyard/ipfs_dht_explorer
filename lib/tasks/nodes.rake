namespace :nodes do
  task discover: :environment do
    Node.discover_connected_peers
  end
end
