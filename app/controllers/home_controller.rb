class HomeController < ApplicationController
  def index
    @user = User.find(session[:user_id]) rescue nil
  end

  def tweets
    @user = User.find(session[:user_id]) rescue nil
    
  end
end
