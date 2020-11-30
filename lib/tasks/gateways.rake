namespace :gateways do
  task pl: :environment do
    total_cids = Cid.count
    total_wants = Want.count
    pl_nodes = Node.pl
    pl_node_ids = pl_nodes.pluck(:id)

    pl_wants = Want.where(node_id: pl_node_ids).count

    puts "total_wants: #{total_wants}"
    puts "pl_wants: #{pl_wants}"
    puts "pl percentage: #{pl_wants/total_wants.to_f*100}"

    puts ""

    all_pl_cids_count = 0

    Cid.includes(:wants).find_each do |cid|
      if cid.wants.map(&:node_id).difference(pl_node_ids).any?
        all_pl_cids_count += 1
      end
    end

    puts "all_pl_cids_count: #{all_pl_cids_count}"
    puts "total_cids: #{total_cids}"
    puts "pl percentage: #{all_pl_cids_count/total_cids.to_f*100}"
  end
end
