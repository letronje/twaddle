class FetchTweets
  @queue = :scheduled
  
  def self.perform
    db = Mongo::Connection.new.db("twonversations")
    User.find_each do |user|
      user.fetch_tweets(db)
      user.fetch_conversations(db)
    end
  end
end
