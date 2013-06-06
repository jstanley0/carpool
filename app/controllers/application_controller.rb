class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate
  before_filter :get_date

  protected

  def authenticate
    authenticate_or_request_with_http_digest(Carpool::REALM) do |username|
      @current_user = User.find_by_name(username)
      @current_user.try :password_digest
    end
  end

  def get_date
    @today = nil
    @today = Date.parse(params[:date]) rescue nil if params[:date]
    @today ||= Date.today
  end

end
