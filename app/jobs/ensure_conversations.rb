class EnsureConversations
  @queue = :scheduled
  
  def self.perform(user_id=nil)
    db = Mongo::Connection.new.db("twaddle")
    users = user_id.nil? ? User.all : User.where(:id => user_id)
    users.each do |user|
      user.ensure_conversations(db)
    end
  end
end
