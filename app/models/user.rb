class User < ActiveRecord::Base
  has_many :authorizations
  validates :name, :nickname, :presence => true
end
