class SessionsController < ApplicationController
  def create
    auth_hash = request.env['omniauth.auth']
    authorization = Authorization.find_by_provider_and_uid(auth_hash["provider"], auth_hash["uid"])

    if authorization
      user = authorization.user
    else
      user = User.new(:name => auth_hash["info"]["name"],
                      :nickname => auth_hash["info"]["nickname"])
      user.authorizations.build(:provider => auth_hash["provider"],
                                :uid => auth_hash["uid"],
                                :location => auth_hash["info"]["location"],
                                :image => auth_hash["info"]["image"])
      user.save!
    end
    
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
