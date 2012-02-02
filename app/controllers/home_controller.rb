class HomeController < ApplicationController
  def index
    @user = User.find(session[:user_id]) rescue nil
  end

  def tweets
    @user = User.find(session[:user_id]) rescue nil
    Twitter.configure do |config|
      config.consumer_key = "AG0C4uMJuDqorn1g0w9DA"
      config.consumer_secret = "eVM08xyDjPmWsLjfo3uRH5Bx4punjMhfa2jDNb0rNk"
      config.oauth_token = @user.twauth.token
      config.oauth_token_secret = @user.twauth.token_secret
    end

    ap Twitter.home_timeline
  end
end
