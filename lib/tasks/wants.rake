namespace :wants do
  task parse: :environment do
    Node.ipfs_client.log_level 'engine', 'debug'

    peers = Hash.new { |hash, key| hash[key] = [] }
    cids = []
    pl_peer_ids = Node.pl.pluck(:node_id)
    gateway_peer_ids = Node.gateway.pluck(:node_id)

    data_path = '/data/ipfs'
    log_name = 'ipfs.log'

    File.delete("#{data_path}/#{log_name}.next") if File.exist?("#{data_path}/#{log_name}.next")
    FileUtils.cp("#{data_path}/#{log_name}", "#{data_path}/#{log_name}.next")
    File.truncate("#{data_path}/#{log_name}", 5)
    `cat #{data_path}/#{log_name}.next | grep -a " wants " > #{data_path}/#{log_name}.short`

    File.open("#{data_path}/#{log_name}.short", "r:ISO-8859-1:UTF-8") do |f|
      f.each_line do |line|
        parts = line.split(' ')
        peers[parts[4]] << [parts[6], parts[0]]
        cids << parts[6]
      end
    end

    puts "peers: #{peers.length}"
    puts "cids: #{cids.length}"

    data = cids.uniq.map{|id, datetime| {cid: id} }

    if data.any?
      records = Cid.upsert_all(data, unique_by: :cid)
      # records.each do |record|
      #   DetectContentTypeWorker.perform_async(record["id"])
      # end
    end

    node_ids = []
    cid_ids = []

    peers.each do |k,v|
      next if k.blank?
      next if pl_peer_ids.include?(k) # skip PL node wants
      next if gateway_peer_ids.include?(k) # skip gateway node wants
      node = Node.find_by_node_id(k)
      if node.nil?
        puts "missing node: #{k}"
        node = Node.create(node_id: k)
        ManualCrawlWorker.perform_async(node.id)
      end
      node_ids << node.id
      v = v.sort.uniq
      cids = Cid.where(cid: v.map(&:first).uniq.compact).select('id, cid')

      cid_map = {}
      cids.each do |cid|
        cid_ids << cid.id
        cid_map[cid.cid] = cid.id
      end

      v.each_slice(1000) do |cid_ids|
        want_data = cid_ids.map{|cid_id, datetime| {node_id: node.id, cid_id: cid_map[cid_id], created_at: datetime } }
        begin
          upserted = Want.upsert_all(want_data, returning: false) if want_data.any?
        rescue ActiveRecord::NotNullViolation
          # invalid log data
        end
      end
    end
    # update wants_count on nodes
    node_counts = Want.where(node_id: node_ids).group(:node_id).count
    node_counts.each_slice(1000) do |counts|
      update_sql = ''
      counts.each do |node_count|
        update_sql += "UPDATE nodes SET wants_count = #{node_count[1]} WHERE id = #{node_count[0]};"
      end
      ActiveRecord::Base.connection.execute(update_sql)
    end

    # update wants_count on cids
    cid_counts = Want.where(cid_id: cid_ids.uniq).group(:cid_id).count
    cid_counts.each_slice(1000) do |counts|
      update_sql = ''
      counts.each do |cid_count|
        update_sql += "UPDATE cids SET wants_count = #{cid_count[1]} WHERE id = #{cid_count[0]};"
      end
      ActiveRecord::Base.connection.execute(update_sql)
    end

    FileUtils.rm ("#{data_path}/#{log_name}.next")
    FileUtils.rm ("#{data_path}/#{log_name}.short")
  end

  task export: :environment do
    start_date = 1.day.ago
    end_date = Time.now
    path = '/data/ipfs/wants.csv'
    Want.export(path, start_date, end_date)
  end

  task cleanup: :environment do
    Want.where('created_at < ?', 7.days.ago).delete_all
  end
end
