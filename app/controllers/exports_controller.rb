class ExportsController < ApplicationController
  def index
    @scope = Export.all

    sort = params[:sort] || 'exports.created_at'
    order = params[:order] || 'desc'

    @pagy, @exports = pagy(@scope.order(sort => order))
  end
end
