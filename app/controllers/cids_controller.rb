class CidsController < ApplicationController
  def index
    @scope = Want.group(:cid_id).count.sort_by{|k,v| -v}.first(1000)

    @pagy, @cids = pagy_array(@scope)
    cids = Cid.where(id: @cids.map(&:first))
    @cids.map!{|k,v| [cids.detect{|c| c.id == k }, v] }
  end

  def recent
    @scope = Want.includes(:cid,:node).order('created_at DESC')

    @pagy, @wants = pagy(@scope)
  end

  def show
    @cid = Cid.find_by_cid!(params[:id])

    @scope = @cid.wants.includes(:node)

    @nodes = @cid.wants.group(:node_id).count.sort_by{|k,v| -v}.first(20).map{|k,v| [Node.find(k), v] }

    @pagy, @wants = pagy(@scope)
  end

  def wants
    @scope = Want.group(:node_id).count.sort_by{|k,v| -v}

    @pagy, @nodes = pagy_array(@scope)
  end
end
