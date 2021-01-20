require 'csv'

class Node < ApplicationRecord
  CURRENT_MINOR_VERSION = 7

  has_many :wants, dependent: :delete_all

  has_many :source_edges, class_name: 'Edge', foreign_key: :source_id
  has_many :source_peers, through: :source_edges, class_name: 'Node'

  has_many :target_edges, class_name: 'Edge', foreign_key: :target_id
  has_many :target_peers, through: :target_edges, class_name: 'Node'

  scope :with_addresses, -> { where.not(multiaddrs: []) }
  scope :only_go_ipfs,  -> { where.not(minor_go_ipfs_version:nil)}
  scope :without_boosters, -> { where.not(agent_version: ['hydra-booster/0.7.0', 'hydra-booster/0.7.3', 'dhtbooster/2']) }
  scope :without_storm, -> { where.not(agent_version: ['storm']) }
  scope :pl, -> { where(pl: true) }
  scope :not_pl, -> { where(pl: false) }
  scope :outdated, -> { where('minor_go_ipfs_version::integer < ?', Node::CURRENT_MINOR_VERSION) }

  scope :gateway, -> { where(gateway: true) }
  scope :not_gateway, -> { where(gateway: false) }

  scope :brave, -> { without_storm.without_boosters.where("array_to_string(multiaddrs, '||') ILIKE :port", port: "%#{BRAVE_PORT}%") }

  BRAVE_PORT = 44001

  GEO_IP_DIR = ENV['GEO_IP_DIR'] || '/usr/local/var/GeoIP'

  GEO_CITY_READER = MaxMind::GeoIP2::Reader.new("#{GEO_IP_DIR}/GeoLite2-City.mmdb")
  GEO_ASN_READER = MaxMind::GeoIP2::Reader.new("#{GEO_IP_DIR}/GeoLite2-ASN.mmdb")
  GEO_DOMAIN_READER = MaxMind::GeoIP2::Reader.new("#{GEO_IP_DIR}/GeoIP2-Domain.mmdb")

  SECIO_PATCH_VERSIONS = [
    '0.4.21',
    '0.4.22',
    '0.4.23',
    '0.4.21-rc3',
    '0.4.21-dev',
    '0.4.21-rc2',
    '0.4.22-rc2',
    '0.4.22-rc1',
    '0.4.22-dev',
    '0.4.23-rc1',
    '0.4.23-rc2'
  ]

  scope :before_secio, -> {where(minor_go_ipfs_version: 4).where.not(patch_go_ipfs_version: SECIO_PATCH_VERSIONS)}

  def to_s
    node_id
  end

  def to_param
    node_id
  end

  def self.export(path, start_date, end_date)
    scope = Node.where('updated_at > ?', start_date).where('updated_at < ?', end_date)
    CSV.open(path, "wb", row_sep: "\r\n") do |csv|
      csv << Node.attribute_names
      scope.find_each(batch_size: 5000) do |node|
        csv << node.attributes.values
      end
    end
    filename = path.split('/').last
    folders = path.split('/')[0..-2].join('/')
    `cd #{folders} && tar -czf #{filename}.tar.gz #{filename}`
    archive_path = "#{folders}/#{filename}.tar.gz"
    records = scope.count
    resp = Node.ipfs_client.add(archive_path)
    Export.create(filename: resp['Name'],
                  kind: 'nodes',
                  cid: resp['Hash'],
                  size: resp['Size'],
                  records: records,
                  description: "Nodes seen between #{start_date.strftime('%b %d, %Y, %l:%M %p')} and #{end_date.strftime('%b %d, %Y, %l:%M %p')}")
    File.delete(path)
    File.delete(archive_path)
  end

  def self.discover_connected_peers
    Node.peers.each do |peer|
      if node = Node.find_by_node_id(peer['Peer'])
        ManualCrawlWorker.perform_async(node.id) if node.agent_version.blank?
      else
        node = Node.create(node_id: peer['Peer'])
        ManualCrawlWorker.perform_async(node.id)
      end
    end
  end

  def self.dial_incomplete_nodes
    Node.where('agent_version = ? or agent_version = ? or multiaddrs = ?', nil, '', '{}').where('last_crawled < ? or last_crawled is ?', 1.day.ago, nil).order('last_crawled ASC nulls first').limit(250).pluck(:id).each do |id|
      ManualCrawlWorker.perform_async(id)
    end
  end

  def self.dial_inactive_nodes
    Node.where('updated_at < ?', 1.day.ago).where('updated_at > ?', 7.days.ago).where('last_crawled < ? or last_crawled is ?', 1.day.ago, nil).order('last_crawled ASC nulls first').limit(250).pluck(:id).each do |id|
      ManualCrawlWorker.perform_async(id)
    end
  end

  def self.dial_secio_nodes
    Node.before_secio.order('last_crawled ASC nulls first').limit(250).pluck(:id).each do |id|
      ManualCrawlWorker.perform_async(id)
    end
  end

  def self.ipfs_client
    @client ||= Ipfs::Client.new( "http://#{ENV.fetch("IPFS_URL") { 'localhost' }}:#{ENV.fetch("IPFS_PORT") { '5001' }}")
  end

  def self.peers
    ipfs_client.swarm_peers['Peers']
  end

  def ipfs_connect
    addrs = public_multi_addrs.first(10).map{|origin| "#{origin}/p2p/#{node_id}" }
    addrs += ["/p2p/#{node_id}"]
    addrs.each do |addr|
      begin
        Node.ipfs_client.swarm_connect(addr)
      rescue Ipfs::Commands::Error => e
        puts e
      end
    end
  end

  def ipfs_id
    begin
      Node.ipfs_client.id(node_id)
    rescue Ipfs::Commands::Error => e
      puts e
    end
  end

  def manual_crawl
    return if last_crawled && last_crawled > 30.minutes.ago
    if ipfs_connect && json = ipfs_id
      updates = {
        multiaddrs: Array(json['Addresses']).map{|a| a.split('/p2p/').first}.sort,
        protocols: Array(json['Protocols']).sort,
        agent_version: json['AgentVersion'],
        sightings: sightings + 1,
        reachable: true,
        last_crawled: Time.now
      }
      update(updates)
      update_minor_go_ipfs_version
      update_patch_go_ipfs_version
      update_location_details
    else
      update_column(:last_crawled, Time.now)
    end
  end

  def geo_details
    return nil unless main_ip
    @geo_details ||= begin
      GEO_CITY_READER.city(main_ip.to_s)
    rescue MaxMind::GeoIP2::AddressNotFoundError
      nil
    end
  end

  def asn_details
    return nil unless main_ip
    @asn_details ||= begin
      GEO_ASN_READER.asn(main_ip.to_s)
    rescue MaxMind::GeoIP2::AddressNotFoundError
      nil
    end
  end

  def domain_details
    @domain_details ||= Node.domain_lookup(ip)
  end

  def self.domain_lookup(ip)
    return unless ip
    begin
      GEO_DOMAIN_READER.domain(ip.to_s).try(:domain)
    rescue MaxMind::GeoIP2::AddressNotFoundError
      nil
    end
  end

  def location_details
    return {} unless geo_details.present?
    return {} unless asn_details.present?
    {
      country_iso_code:               geo_details.country.iso_code,
      country_name:                   geo_details.country.name,
      most_specific_subdivision_name: geo_details.most_specific_subdivision.try(:name),
      city_name:                      geo_details.city.name,
      postal_code:                    geo_details.postal.code,
      accuracy_radius:                geo_details.location.accuracy_radius,
      latitude:                       geo_details.location.latitude,
      longitude:                      geo_details.location.longitude,
      network:                        geo_details.traits.network,
      autonomous_system_number:       asn_details.autonomous_system_number,
      autonomous_system_organization: asn_details.autonomous_system_organization,
      domains: domain_names
      }
  end

  def update_location_details
    return unless geo_details.present?
    return unless asn_details.present?
    update(location_details)
  end

  def update_domains
    update(domains: domain_names)
  end

  def domain_names
    ip_addresses.map{|ip| Node.domain_lookup(ip) }.compact.uniq
  end

  def main_ip
    main_ip4 || main_ip6
  end

  def main_ip4
    ip4_addresses.first
  end

  def main_ip6
    ip6_addresses.first
  end

  def ip_addresses
    ip4_addresses + ip6_addresses
  end

  def public_multi_addrs
    multiaddrs.select do |a|
      begin
        ip = IPAddr.new(a.split('/')[2])
        !ip.loopback? && !ip.private? && !ip.link_local?
      rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
        false
      end
    end
  end

  def ip4_addresses
    return [] unless multiaddrs
    multiaddrs.select{|a| a.split('/')[1] == 'ip4' }.map{|a| IPAddr.new(a.split('/')[2]) }.uniq.select{|a| !a.loopback? && !a.private? && !a.link_local?  }
  end

  def ip6_addresses
    return [] unless multiaddrs
    multiaddrs.select{|a| a.split('/')[1] == 'ip6' }.map{|a| IPAddr.new(a.split('/')[2]) }.uniq.select{|a| !a.loopback? && !a.private? && !a.link_local?  }
  end

  def minor_go_ipfs_version
    return unless agent_version.present?
    return unless agent_version.include?('go-ipfs')
    agent_version.split('/')[agent_version.split('/').index('go-ipfs')+1].split('.')[1]
  end

  def update_minor_go_ipfs_version
    return unless minor_go_ipfs_version.present?
    update(minor_go_ipfs_version: minor_go_ipfs_version)
  end

  def patch_go_ipfs_version
    return unless agent_version.present?
    return unless agent_version.include?('go-ipfs')
    agent_version.split('/')[agent_version.split('/').index('go-ipfs')+1]
  end

  def update_patch_go_ipfs_version
    return unless patch_go_ipfs_version.present?
    update(patch_go_ipfs_version: patch_go_ipfs_version)
  end

  def update_peers_count
    update(peers_count: peers.count)
  end

  def self.update_peers_counts
    e = Edge.group(:source_id).count
    Node.where(reachable: true).each {|n| n.update(peers_count: e[n.id] || 0)}
  end

  def self.import_from_crawler
    file = File.open("/Users/andrewnesbitt/go/src/ipfs-crawler/output_data_crawls/visitedPeers_05-10-20--10:42:16_05-10-20--10:46:52.json")
    data = JSON.load(file)
    data['Nodes'].each do |node|
      n = Node.find_or_create_by(node_id: node['NodeID'])
      n.update(multiaddrs: node['MultiAddrs'], reachable: node['reachable'], agent_version: node['agent_version'])
    end
  end

  def self.import_from_other_crawler
    file = File.open("/Users/andrewnesbitt/code/libp2p-dht-scrape-client/output.json")
    data = JSON.load(file)
    data.each do |peer_id, node|
      n = Node.find_or_create_by(node_id: node['peerID'])

      updates = {}
      updates[:multiaddrs] = (Array(node['addresses']) + Array(n.multiaddrs)).uniq
      updates[:protocols] = (Array(node['protocols']) + Array(n.protocols)).uniq
      updates[:reachable] = node['agentVersion'].present?
      updates[:agent_version] = node['agentVersion'] if node['agentVersion'].present?

      n.update(updates)
    end
    return true
  end

  def self.import_from_counter
    file = File.open("data/output.json")
    data = JSON.load(file)
    data.each do |peer_id, peer_values|
      puts peer_id
      # TODO sightings
      # TODO last connected

      n = Node.find_by_node_id(peer_id)
      if n
        updates = {}
        updates[:sightings] = peer_values['n']
        updates[:updated_at] = peer_values['ls']
        updates[:created_at] = peer_values['fs']
        updates[:protocols] = (Array(peer_values['ps']) + Array(n.protocols)).uniq

        if peer_values['a'].present? && Array(peer_values['a']) != Array(n.multiaddrs)
          n.multiaddrs = (Array(peer_values['a']) + Array(n.multiaddrs)).uniq
          updates[:multiaddrs] = (Array(peer_values['a']) + Array(n.multiaddrs)).uniq
          updates[:domains] = n.domain_names
          updates.merge!(n.location_details)
        end

        if peer_values['av'].present? && n.agent_version != peer_values['av']
          n.agent_version = peer_values['av']
          updates[:agent_version] = peer_values['av']
          updates[:minor_go_ipfs_version] = n.minor_go_ipfs_version
          updates[:patch_go_ipfs_version] = n.patch_go_ipfs_version
          updates[:reachable] = true
        end
        n.update_columns(updates)
      else

        node_attrs = {
          node_id: peer_id,
          multiaddrs: Array(peer_values['a']),
          agent_version: peer_values['av'],
          protocols: Array(peer_values['ps']),
          reachable: peer_values['av'].present?,
          updated_at: peer_values['ls'],
          created_at: peer_values['fs'],
          sightings: peer_values['n']
        }
        node = Node.new(node_attrs)

        if node.multiaddrs.any?
          node.domains = node.domain_names
          node.assign_attributes(node.location_details)
        end

        if node.agent_version.present?
          node.minor_go_ipfs_version = node.minor_go_ipfs_version
          node.patch_go_ipfs_version = node.patch_go_ipfs_version
        end

        node.save rescue ArgumentError
      end
    end
    puts "#{data.keys.length} peers imported"
    return nil
  end

  def self.update_location_details
    Node.all.find_each(&:update_location_details)
  end

  def self.update_minor_go_ipfs_version
    Node.where.not(agent_version: '').where(minor_go_ipfs_version: nil).find_each(&:update_minor_go_ipfs_version)
  end

  def self.import_and_update
    Node.import_from_other_crawler
    Node.import_from_crawler
    Node.update_peers_counts
    Node.update_location_details
    Node.update_minor_go_ipfs_version
  end

  def self.mark_pl_nodes
    csv = CSV.read('/data/pl_nodes.csv', headers: true)
    csv.each do |row|
      next if row['peer_id'].blank?
      node = Node.find_or_create_by(node_id: row['peer_id'])
      node.update(pl: true)
    end
  end
end
