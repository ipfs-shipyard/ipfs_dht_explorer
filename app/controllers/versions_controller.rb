class VersionsController < ApplicationController
  def show
    @version = params[:id]

    @scope = Node.where(agent_version: @version).not_pl

    @range = (params[:range].presence || 7).to_i
    @scope = @scope.where('nodes.updated_at > ?', @range.days.ago)

    sort = params[:sort] || 'nodes.wants_count'
    order = params[:order] || 'desc'

    if params[:tab] == 'wants'
      @wants = Want.where(node_id: @scope.pluck(:id)).group(:cid_id).order('count_all desc').count
    end
  end

  def show_chart
    @version = params[:id]

    @scope = Node.where(agent_version: @version).not_pl

    @range = (params[:range].presence || 7).to_i
    @scope = @scope.where('nodes.updated_at > ?', @range.days.ago)

    @graph = {}
    (Date.today-(@range - 1)..Date.today).map do |d|
      count = @scope.where('updated_at >= ?', d).where('created_at <= ?', d).count
      @graph[d] = count
    end

    render json: @graph
  end
end
