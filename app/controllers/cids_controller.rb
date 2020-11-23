class CidsController < ApplicationController
  def index
    @range = (params[:range].presence || 7).to_i
    @scope = Want.where('created_at > ?', @range.days.ago).group(:cid_id).count.sort_by{|k,v| -v}

    @pagy, @cids = pagy_array(@scope)
    cids = Cid.where(id: @cids.map(&:first))
    @cids.map!{|k,v| [cids.detect{|c| c.id == k }, v] }
  end

  def recent
    @range = (params[:range].presence || 7).to_i
    @scope = Want.where('created_at > ?', @range.days.ago).includes(:cid,:node).order('created_at DESC')

    @pagy, @wants = pagy(@scope)
  end

  def show
    @cid = Cid.find_by_cid!(params[:id])

    @scope = @cid.wants.includes(:node)

    @nodes = @cid.wants.group(:node_id).count.sort_by{|k,v| -v}.first(20).map{|k,v| [Node.find(k), v] }

    @pagy, @wants = pagy(@scope)
  end

  def wants
    @range = (params[:range].presence || 7).to_i
    @scope = Want.group(:node_id).where('created_at > ?', @range.days.ago).count.sort_by{|k,v| -v}

    @pagy, @nodes = pagy_array(@scope)
  end
end
