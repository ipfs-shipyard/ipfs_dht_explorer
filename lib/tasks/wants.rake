namespace :wants do
  task parse: :environment do
    peers = Hash.new { |hash, key| hash[key] = [] }
    cids = []

    data_path = '/data'

    File.delete("#{data_path}/want-logs.txt.next") if File.exist?("#{data_path}/want-logs.txt.next")
    FileUtils.cp("#{data_path}/want-logs.txt", "#{data_path}/want-logs.txt.next")
    File.truncate("#{data_path}/want-logs.txt", 5)

    wc_output = `wc -l #{data_path}/want-logs.txt.next`.to_i

    File.open("#{data_path}/want-logs.txt.next", "r") do |f|
      f.each_line.with_index do |line,i|
        next if i == wc_output # skip last line of file
        if line.match?(' wants ')
          parts = line.split(' ')
          peers[parts[6]] << [parts[8], parts[2]]
          cids << parts[8]
        end
      end
    end

    data = cids.uniq.map{|id, datetime| {cid: id} }

    ids = Cid.upsert_all(data, unique_by: :cid) if data.any?
    puts ids.length

    node_ids = []
    cid_ids = []

    peers.each do |k,v|
      next if k.blank?
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

    FileUtils.rm ("#{data_path}/want-logs.txt.next")
  end
end
