class SessionsController < ApplicationController
  def create
    auth_hash = request.env['omniauth.auth']

    info = auth_hash["info"]
    access_token = auth_hash["extra"]["access_token"]
    
    authorization = Authorization.find_by_provider_and_uid(auth_hash["provider"],
                                                           auth_hash["uid"])

    if authorization
      user = authorization.user
      authorization.update_attributes!(:token => access_token.token,
                                       :token_secret => access_token.secret)
    else
      user = User.new(:name => info["name"],
                      :nickname => info["nickname"])

      user.authorizations.build(:provider => auth_hash["provider"],
                                :uid => auth_hash["uid"],
                                :location => info["location"],
                                :image => info["image"],
                                :token => access_token.token,
                                :token_secret => access_token.secret)
      
      user.save!
    end

    Resque.enqueue(EnsureConversations, user.id)

    session[:user_id] = user.id
    redirect_to root_path
  end

  def failure
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
  
end
