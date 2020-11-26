class CidsController < ApplicationController
  def index
    @scope = Cid.where('wants_count > 0')

    @scope = @scope.where(content_type: params[:content_type]) if params[:content_type].present?

    @content_types = @scope.unscope(where: :content_type).where.not(content_type: nil).group(:content_type).count

    @pagy, @cids = pagy(@scope.order('wants_count DESC'))
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
    @scope = Node.order('wants_count DESC').where('wants_count > 0')
    @pagy, @nodes = pagy(@scope)
  end
end
