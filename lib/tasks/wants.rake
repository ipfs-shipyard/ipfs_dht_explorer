namespace :wants do
  task parse: :environment do
    peers = Hash.new { |hash, key| hash[key] = [] }
    cids = []

    data_path = '/data'

    File.delete("#{data_path}/want-logs.txt.next") if File.exist?("#{data_path}/want-logs.txt.next")
    FileUtils.cp("#{data_path}/want-logs.txt", "#{data_path}/want-logs.txt.next")
    File.truncate("#{data_path}/want-logs.txt", 5)

    File.open("#{data_path}/want-logs.txt.next", "r") do |f|
      f.each_line.with_index do |line,i|
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

    peers.each do |k,v|
      next if k.blank?
      node = Node.find_by_node_id(k)
      if node.nil?
        puts "missing node: #{k}"
        node = Node.create(node_id: k)
        next
      end
      v = v.sort.uniq
      cids = Cid.where(cid: v.map(&:first).uniq).select('id, cid')

      cid_map = {}
      cids.each do |cid|
        cid_map[cid.cid] = cid.id
      end

      v.each_slice(1000) do |cid_ids|
        want_data = cid_ids.map{|cid_id, datetime| {node_id: node.id, cid_id: cid_map[cid_id], created_at: datetime } }
        upserted = Want.upsert_all(want_data, returning: false) if want_data.any?
        upserted.length
      end
    end

    FileUtils.rm ("#{data_path}/want-logs.txt.next")
  end
end
