namespace :wants do
  task parse: :environment do
    peers = Hash.new { |hash, key| hash[key] = [] }
    cids = []

    # have_peers = Hash.new { |hash, key| hash[key] = [] }
    # haves = []
    #
    # first_time = nil
    # last_time = nil
    #
    #

    # File.open("data/ipfs_wants.log", "r") do |f|
    #   f.each_line.with_index do |line,i|
    #
    #     if line.match?(' wants ')
    #       # print '.'
    #       parts = line.split(' ')
    #
    #       # node = Node.find_by_node_id(parts[6])
    #       # next if node.nil?
    #       # cid = Cid.find_or_create_by(cid: parts[8])
    #       # want = Want.create(node_id: node.id, cid_id: cid.id, created_at: parts[0])
    #       # puts want.id
    #       # first_time = DateTime.parse(parts[0]).to_time if first_time.nil?
    #       # last_time = parts[0]
    #
    #       peers[parts[6]] << parts[8]
    #       cids << parts[8]
    #
    #     # elsif line.match?('want-have')
    #         # parts = line.split('want-have')
    #         # json = JSON.parse(parts[1])
    #         # have_peers[json['from']] << json['cid']
    #         # haves << json['cid']
    #     end
    #   end
    # end

    File.open("data/logs.txt", "r") do |f|
      f.each_line.with_index do |line,i|
        if line.match?(' wants ')
          parts = line.split(' ')
          peers[parts[6]] << parts[8]
          cids << parts[8]
        end
      end
    end

    puts peers.keys.length
    puts cids.uniq.length

    data = cids.uniq.map{|id| {cid: id} }
    ids = Cid.insert_all(data, unique_by: :cid)
    puts ids.length
    puts
    peers.each do |k,v|
      node = Node.find_by_node_id(k)
      if node.nil?
        puts "missing node: #{k}"
        next
      end
      cids = Cid.where(cid: v.uniq).pluck(:id)
      p k
      p v.length
      p cids.length

      cids.each_slice(1000) do |cid_ids|
        print ''
        want_data = cid_ids.map{|cid_id| {node_id: node.id, cid_id: cid_id, created_at: Time.now } }
        Want.insert_all(want_data, returning: false)
      end

      # want_data = v.map{|cid_str| {node_id: node.id, cid_id: cids.detect{|cid| cid.cid == cid_str }.id, created_at: Time.now }}
      # p want_data.length
      # ids = Want.insert_all(want_data)
      # p id.length
      # puts
    end

    # puts ""
    #
    # last_time = DateTime.parse(last_time).to_time
    # diff = last_time - first_time
    # puts "Over #{diff/60.0} minutes"
    # puts "#{cids.length/diff.to_f} wants/second"
    #
    # puts ""
    #
    # puts "#{peers.keys.length} unique peers"
    # known = Node.where(node_id: peers.keys).count
    # puts "#{known} known peers"
    # puts "#{(have_peers.keys + peers.keys).uniq.length} total peers"
    # puts ""
    # puts "#{cids.uniq.length} unique cids"
    # puts "#{cids.length} total wants"
    #
    # puts ""
    # puts "Peers"
    # puts ""
    #
    # peers.sort_by{|k,v| -v.length}.first(20).each do |k,v|
    #   n = Node.find_by_node_id(k)
    #   if n
    #     node = n.id
    #   else
    #     node = ''
    #   end
    #   puts "#{k} - #{v.length} (#{v.uniq.length} unique) - #{node}"
    # end
    #
    # puts ""
    # puts "cids"
    # puts ""
    #
    # cids.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.sort_by{|k,v| -v}.first(20).each do |k,v|
    #   puts "#{k} - #{v}"
    # end
    #
    # puts ""
    # puts "126ers"
    # puts ""
    #
    # # matches = peers.to_a.select{|k,v| v.uniq.length == 126}.map{|perp| perp[1]}.flatten.uniq
    # # p matches.length
    #
    # # matches.sort.each do |cid|
    # #   puts cid
    # # end
    #
    # peers.select{|k,v| v.uniq.length == 126}.each do |k,v|
    #   puts "#{k} - #{v.length} (#{v.uniq.length} unique)"
    # end
    #
    # puts ""
    # puts "haves"
    # puts ""
    # puts "#{have_peers.keys.length} have peers"
    # puts "#{haves.uniq.length} cids"
    # puts "#{haves.length} haves"
    #
    # have_peers.sort_by{|k,v| -v.length}.first(20).each do |k,v|
    #   n = Node.find_by_node_id(k)
    #   if n
    #     node = "*"
    #   else
    #     node = ''
    #   end
    #   puts "#{k}#{node} - #{v.length} (#{v.uniq.length} unique)"
    # end
    # puts ""
    # haves.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.sort_by{|k,v| -v}.first(20).each do |k,v|
    #   puts "#{k} - #{v}"
    # end
  end
end
