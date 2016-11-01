class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # after_action :set_csrf_cookie_for_ng
  def index
  	render "layouts/application.html.erb" 
  end

  private
  
  # def set_csrf_cookie_for_ng
  #   cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  # end

end
