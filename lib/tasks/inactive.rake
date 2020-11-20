namespace :inactive do
  task dial: :environment do
    nodes = Node.only_go_ipfs.where('updated_at < ?', 1.days.ago).where('nodes.updated_at > ?', 7.days.ago).with_addresses

    connected = []
    failed = []

    nodes.each do |node|
      puts node.node_id
      puts "connecting"
      node.ipfs_connect
      if id = node.ipfs_id
        puts "connected"
        p id
        connected << node.node_id
      else
        puts "failed"
        failed << node.node_id
      end
    end

    puts ""
    puts "connected: #{connected.length}"
    puts "failed: #{failed.length}"

    puts "connected:"
    puts ""
    connected.each do |node_id|
      puts node_id
    end
  end
end
