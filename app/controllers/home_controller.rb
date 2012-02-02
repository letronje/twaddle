class HomeController < ApplicationController
  def index
    @user = User.find(session[:user_id]) rescue nil
  end
end
