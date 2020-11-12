class NodesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :report
  skip_before_action :authenticate_user!, only: :report

  def overview
    @scope = Node.only_go_ipfs
    @range = params[:range] ||= 14
    apply_filters
  end

  def index
    @scope = Node.all

    apply_filters

    sort = params[:sort] || 'nodes.id'
    order = params[:order] || 'desc'

    @pagy, @nodes = pagy(@scope.order(sort => order))
  end

  def report
    existing_nodes = Node.where(node_id: params["peers"].keys)
    upserts = []

    excluded_attribute_names = ["id","country_iso_code","country_name",
      "most_specific_subdivision_name","city_name","postal_code","accuracy_radius",
      "latitude","longitude","network","autonomous_system_number","autonomous_system_organization","domains"]

    params["peers"].each do |peer_id, peer_values|
      n = existing_nodes.detect{|node| node.node_id == peer_id}
      if n
        updates = {}
        updates[:sightings] = n.sightings + 1
        updates[:updated_at] = Time.now
        updates[:protocols] = Array(n.protocols)

        updates[:multiaddrs] = (Array(peer_values['addresses']) + Array(n.multiaddrs)).uniq

        if peer_values['agentVersion'].present? && n.agent_version != peer_values['agentVersion']
          n.agent_version = peer_values['agentVersion']
          updates[:agent_version] = peer_values['agentVersion']
          updates[:minor_go_ipfs_version] = n.minor_go_ipfs_version
          updates[:patch_go_ipfs_version] = n.patch_go_ipfs_version
          updates[:reachable] = true
        end
        n.assign_attributes(updates)
        upserts << n.attributes.except(*excluded_attribute_names)
      else

        node_attrs = {
          node_id: peer_id,
          multiaddrs: Array(peer_values['addresses']),
          agent_version: peer_values['agentVersion'],
          protocols: Array(peer_values['protocols']),
          reachable: peer_values['agentVersion'].present?,
          sightings: 1,
          updated_at: Time.now,
          created_at: Time.now
        }
        node = Node.new(node_attrs)

        if node.agent_version.present?
          node.minor_go_ipfs_version = node.minor_go_ipfs_version
          node.patch_go_ipfs_version = node.patch_go_ipfs_version
        end
        upserts << node.attributes.except(*excluded_attribute_names)
      end
    end

    inserted = Node.upsert_all(upserts, unique_by: :node_id)

    inserted.each{|id| ResolveMultiaddrsWorker.perform_async(id) }

    head :ok
  end

  def show
    @node = Node.find_by_node_id!(params[:id])
  end

  def countries
    @scope = Node.all
    apply_filters
    @count = @scope.count
    @pagy, @country_iso_codes = pagy_array(@scope.group(:country_iso_code).count.reject{|k,v| k.blank?}.sort_by{|k,v| -v}, items: 5)
  end

  def versions
    @scope = Node.where.not(minor_go_ipfs_version: nil)
    apply_filters
    @count = @scope.count
    @minor_go_ipfs_versions = @scope.group(:minor_go_ipfs_version).count.reject{|k,v| k.blank?}.sort_by{|k,v| k}
  end

  def secio
    @scope = Node.before_secio
    apply_filters
    @patch_go_ipfs_versions = @scope.group(:patch_go_ipfs_version).count
    sort = params[:sort] || 'nodes.id'
    order = params[:order] || 'desc'

    @pagy, @nodes = pagy(@scope.order(sort => order))
  end

  def storm
    @scope = Node.where(agent_version: 'storm')
    apply_filters
    sort = params[:sort] || 'nodes.id'
    order = params[:order] || 'desc'

    @pagy, @nodes = pagy(@scope.order(sort => order))
  end

  def apply_filters
    if params[:range].present?
      @range = (params[:range].presence || 30).to_i
      @scope = @scope.where('nodes.updated_at > ?', @range.days.ago)
    end

    @scope = @scope.where(":multiaddrs = ANY (multiaddrs)", multiaddrs: params[:addr]) if params[:addr].present?
    @scope = @scope.where("array_to_string(multiaddrs, '||') ILIKE :ip", ip: "%#{params[:ip4]}%") if params[:ip4].present?
    @scope = @scope.where(":protocols = ANY (protocols)", protocols: params[:protocols]) if params[:protocols].present?
    @scope = @scope.where(":domains = ANY (domains)", domains: params[:domain_name]) if params[:domain_name].present?

    @scope = @scope.without_storm if params[:without_storm].present?
    @scope = @scope.without_boosters if params[:without_boosters].present?
    @scope = @scope.with_addresses if params[:with_addresses].present?
    @scope = @scope.only_go_ipfs if params[:only_go_ipfs].present?

    @scope = @scope.where(autonomous_system_organization: params[:asn]) if params[:asn].present?
    @scope = @scope.where(country_name: params[:country_name]) if params[:country_name].present?
    @scope = @scope.where(agent_version: params[:agent_version]) if params[:agent_version].present?
    @scope = @scope.where(reachable: params[:reachable]) if params[:reachable].present?
    @scope = @scope.where(city_name: params[:city_name]) if params[:city_name].present?
    @scope = @scope.where(network: params[:network]) if params[:network].present?
    @scope = @scope.where(minor_go_ipfs_version: params[:minor_go_ipfs_version]) if params[:minor_go_ipfs_version].present?
    @scope = @scope.where(patch_go_ipfs_version: params[:patch_go_ipfs_version]) if params[:patch_go_ipfs_version].present?

    @scope = @scope.where.not(autonomous_system_organization: params[:exclude_asn]) if params[:exclude_asn].present?
    @scope = @scope.where.not(country_name: params[:exclude_country_name]) if params[:exclude_country_name].present?
    @scope = @scope.where.not(agent_version: params[:exclude_agent_version]) if params[:exclude_agent_version].present?
    @scope = @scope.where.not(reachable: params[:exclude_reachable]) if params[:exclude_reachable].present?
    @scope = @scope.where.not(city_name: params[:exclude_city_name]) if params[:exclude_city_name].present?
    @scope = @scope.where.not(network: params[:exclude_network]) if params[:exclude_network].present?
    @scope = @scope.where.not(minor_go_ipfs_version: params[:exclude_minor_go_ipfs_version]) if params[:exclude_minor_go_ipfs_version].present?
    @scope = @scope.where.not(patch_go_ipfs_version: params[:exclude_patch_go_ipfs_version]) if params[:exclude_patch_go_ipfs_version].present?

    @agent_version_scope = @scope.unscope(where: :agent_version)
    @agent_version_scope = @agent_version_scope.without_storm if params[:without_storm].present?
    @agent_version_scope = @agent_version_scope.without_boosters if params[:without_boosters].present?

    @agent_versions = @agent_version_scope.group(:agent_version).count

    @domains = @scope.unscope(where: :domains).pluck(:domains).flatten.compact.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.sort_by{|k,v| -v}
    @reachables = @scope.unscope(where: :reachable).group(:reachable).count
    @autonomous_system_organizations = @scope.unscope(where: :autonomous_system_organization).group(:autonomous_system_organization).count
    @country_names = @scope.unscope(where: :country_name).group(:country_name).count
    @minor_go_ipfs_versions = @scope.unscope(where: :minor_go_ipfs_version).group(:minor_go_ipfs_version).count
    @patch_go_ipfs_versions = @scope.unscope(where: :patch_go_ipfs_version).group(:patch_go_ipfs_version).count
  end
end
