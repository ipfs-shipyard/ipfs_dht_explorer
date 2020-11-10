class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include Pagy::Backend

  def authenticate_user!
    return if logged_in?
    respond_to do |format|
      format.html { redirect_to login_path, flash: {error: 'Unauthorized access, please log in first'} }
      format.json { render json: { "error" => "unauthorized" }, status: :unauthorized }
    end
  end

  helper_method :current_user
  def current_user
    @current_user ||= cookies.permanent.signed[:username]
  end

  helper_method :logged_in?
  def logged_in?
    !current_user.nil?
  end
end
