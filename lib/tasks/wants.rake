namespace :wants do
  task parse: :environment do
    peers = Hash.new { |hash, key| hash[key] = [] }
    cids = []

    File.open("data/logs.txt", "r") do |f|
      f.each_line.with_index do |line,i|
        if line.match?(' wants ')
          parts = line.split(' ')
          peers[parts[6]] << [parts[8], parts[2]]
          cids << parts[8]
        end
      end
    end

    data = cids.uniq.map{|id, datetime| {cid: id} }

    # TODO it may be faster to only insert new here
    ids = Cid.upsert_all(data, unique_by: :cid)
    puts ids.length

    peers.each do |k,v|
      node = Node.find_by_node_id(k)
      if node.nil?
        puts "missing node: #{k}"
        next
      end
      v = v.sort.uniq
      cids = Cid.where(cid: v.map(&:first).uniq)
      p k
      p v.length
      p cids.length

      v.each_slice(1000) do |cid_ids|
        want_data = cid_ids.map{|cid_id, datetime| {node_id: node.id, cid_id: cids.detect{|cid| cid.cid == cid_id }.id, created_at: datetime } }
        upserted = Want.upsert_all(want_data, returning: false)
        puts upserted.length
      end
    end
  end
end
