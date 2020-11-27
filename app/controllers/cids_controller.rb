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

    @range = (params[:range].presence || 7).to_i
    @scope = @cid.wants.includes(:node).where('created_at > ?', @range.days.ago)

    @nodes = @cid.nodes.group_by(&:id).map{|k,v| [v.first, v.length]}

    @pagy, @wants = pagy(@scope)
  end

  def wants
    redirect_to wants_nodes_path
  end
end
