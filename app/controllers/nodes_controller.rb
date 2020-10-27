class NodesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :report

  def index
    @scope = Node.without_boosters.without_storm

    apply_filters

    @pagy, @nodes = pagy(@scope.order('peers_count DESC'), items: 100)
  end

  def report
    n = Node.find_or_create_by(node_id: params['peerID'])

    updates = {}
    updates[:multiaddrs] = (Array(params['addresses']) + Array(n.multiaddrs)).uniq
    updates[:protocols] = (Array(params['protocols']) + Array(n.protocols)).uniq
    updates[:reachable] = params['agentVersion'].present?
    updates[:agent_version] = params['agentVersion'] if params['agentVersion'].present?
    updates[:updated_at] = Time.now
    updates[:minor_go_ipfs_version] = n.minor_go_ipfs_version
    n.update(updates)
    n.update_location_details
    head :ok
  end

  def show
    @node = Node.find(params[:id])
  end

  def countries
    @scope = Node.without_boosters.without_storm
    @scope = @scope.where(reachable: params[:reachable]) if params[:reachable].present?
    @count = @scope.count
    @country_names = @scope.group(:country_name).count.reject{|k,v| k.blank?}.sort_by{|k,v| -v}.first(15)
  end

  def storm
    @scope = Node.where(agent_version: 'storm')
    apply_filters
    @pagy, @nodes = pagy(@scope.order('peers_count DESC'))
  end

  def apply_filters
    @scope = @scope.where(":multiaddrs = ANY (multiaddrs)", multiaddrs: params[:addr]) if params[:addr].present?
    @scope = @scope.where("array_to_string(multiaddrs, '||') ILIKE :ip", ip: "%#{params[:ip4]}%") if params[:ip4].present?
    @scope = @scope.where(":protocols = ANY (protocols)", protocols: params[:protocols]) if params[:protocols].present?
    @scope = @scope.where(autonomous_system_organization: params[:asn]) if params[:asn].present?
    @scope = @scope.where(country_name: params[:country_name]) if params[:country_name].present?
    @scope = @scope.where(agent_version: params[:agent_version]) if params[:agent_version].present?
    @scope = @scope.where(reachable: params[:reachable]) if params[:reachable].present?
    @scope = @scope.where(city_name: params[:city_name]) if params[:city_name].present?
    @scope = @scope.where(minor_go_ipfs_version: params[:minor_go_ipfs_version]) if params[:minor_go_ipfs_version].present?

    @protocols = @scope.unscope(where: :protocols).pluck(:protocols).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
    @reachables = @scope.unscope(where: :reachable).group(:reachable).count
    @agent_versions = @scope.unscope(where: :agent_version).without_boosters.without_storm.group(:agent_version).count
    @autonomous_system_organizations = @scope.unscope(where: :autonomous_system_organization).group(:autonomous_system_organization).count
    @country_names = @scope.unscope(where: :country_name).group(:country_name).count
    @city_names = @scope.unscope(where: :city_name).group(:city_name).count
    @minor_go_ipfs_versions = @scope.unscope(where: :minor_go_ipfs_version).group(:minor_go_ipfs_version).count
  end
end
