class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if logged_in?
  end

  def create
    client = Octokit::Client.new(access_token: auth_hash.credentials.token)
    username = auth_hash.info.nickname
    if organization_member?(client, user: username)
      cookies.permanent.signed[:username] = {value: username, httponly: true}
      redirect_to request.env['omniauth.origin'] || root_path
    else
      flash[:error] = 'Access denied.'
      redirect_to login_path
    end
  end

  def destroy
    cookies.delete :username
    redirect_to login_path
  end

  def failure
    flash[:error] = 'There was a problem authenticating with GitHub, please try again.'
    redirect_to root_path
  end

  private

  def auth_hash
    @auth_hash ||= request.env['omniauth.auth']
  end

  def organization_member?(client, user:)
    client.organization_member?('ipfs', user, headers: { 'Cache-Control' => 'no-cache, no-store' })
  end
end
