class User < ActiveRecord::Base
  has_many :authorizations
  validates :name, :nickname, :presence => true

  def twauth
    authorizations.first
  end

  def twitter_client
    Twitter::Client.new(:consumer_key => "AG0C4uMJuDqorn1g0w9DA",
                        :consumer_secret => "eVM08xyDjPmWsLjfo3uRH5Bx4punjMhfa2jDNb0rNk",
                        :oauth_token => twauth.token,
                        :oauth_token_secret => twauth.token_secret)
  end

  def tweets_collection(db)
    Util::Mongo.user_tweets_collection(db, self)
  end
  
  def fetch_tweets(db)
    twitter = twitter_client
    coll = tweets_collection(db)

    max_attempts = 10
    tweets_per_attempt = 200

    if coll.count.zero?
      tweets = 1.upto(max_attempts).reduce([]) { |all_tweets, n|
        if all_tweets.empty?
          params = {
            :page => 1,
            :count => tweets_per_attempt,
            :include_entities => true,
            :exclude_replies => false
          }
        else
          params = {
            :max_id => all_tweets.last.id-1,
            :count => tweets_per_attempt,
            :include_entities => true,
            :exclude_replies => false
          }
        end

        tweets = twitter.home_timeline(params)

        break all_tweets if tweets.size <= 1
        
        all_tweets + tweets
      }.reverse

    else
      tweets = 1.upto(max_attempts).reduce([]) { |all_tweets, n|
        if all_tweets.empty?
          last_id = coll.find.sort([["_id", -1]]).limit(1).to_a.first["id"]
        else
          last_id = all_tweets.last.id
        end

        tweets = twitter.home_timeline(:since_id => last_id,
                                       :count => tweets_per_attempt,
                                       :include_entities => true,
                                       :exclude_replies => false)

        break all_tweets if tweets.empty?

        all_tweets + tweets.reverse
      }
    end

    tweets.each {|t| coll.insert t.to_hash}
  end

  def reply_tweets(db)
    tweets = tweets_collection(db)
    tweets.find({:in_reply_to_status_id => {"$ne" => nil}}).to_a
  end
  
  def fetch_conversations(db)
    twitter = twitter_client

    reply_tweets(db).each do |r|
      Util::Mongo.ensure_tweet_ancestry(db, r, twitter)
    end
  end
end
