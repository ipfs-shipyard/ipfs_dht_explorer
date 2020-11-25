class CidsController < ApplicationController
  def index
    @scope = Cid.order('wants_count DESC')

    @pagy, @cids = pagy(@scope)
  end

  def recent
    @range = (params[:range].presence || 7).to_i
    @scope = Want.where('created_at > ?', @range.days.ago).includes(:cid,:node).order('created_at DESC')

    @pagy, @wants = pagy(@scope)
  end

  def show
    @cid = Cid.find_by_cid!(params[:id])

    @scope = @cid.wants.includes(:node)

    @nodes = @cid.wants.group(:node_id).count.sort_by{|k,v| -v}.first(30).map{|k,v| [Node.find(k), v] }

    @pagy, @wants = pagy(@scope)
  end

  def wants
    @scope = Node.order('wants_count DESC')
    @pagy, @nodes = pagy(@scope)
  end
end
