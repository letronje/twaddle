class User < ActiveRecord::Base
  has_many :authorizations
  validates :name, :nickname, :presence => true

  def twauth
    authorizations.first
  end
end
