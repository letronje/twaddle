class EnsureConversations
  @queue = :scheduled
  
  def self.perform(user_id=nil)
    users = user_id.nil? ? User.all : User.where(:id => user_id)
    users.each(&:ensure_conversations)
  end
end
