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

  def replies_collection(db)
    Util::Mongo.user_replies_collection(db, self)
  end
  
  def fetch_replies(db)
    twitter = twitter_client
    coll = self.replies_collection(db)

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

        s=Time.now
        tweets = twitter.home_timeline(:since_id => last_id,
                                       :count => tweets_per_attempt,
                                       :include_entities => true,
                                       :exclude_replies => false)
        e=Time.now
        puts "timeline took #{e-s}"
        break all_tweets if tweets.empty?

        all_tweets + tweets.reverse
      }
    end

    replies = tweets.reject { |t| t.in_reply_to_status_id.nil? }
    replies.each { |t| coll.insert t.to_hash }
  end

  # def reply_tweets(db)
  #   tweets = tweets_collection(db)
  #   tweets.find({:in_reply_to_status_id => {"$ne" => nil}}).to_a
  # end

  def replies(db)
    replies_collection(db).find.to_a
  end
  
  def ensure_tweets_ancestry(db)
    twitter = twitter_client

    tweets = replies(db)

    begin
      loop do
        pids = tweets.map{ |r| r["in_reply_to_status_id"] }.reject(&:nil?).uniq
        break if pids.empty?
        Util::Mongo.ensure_tweets(db, pids, twitter)
        tweets = pids.map { |pid| Util::Mongo.ensure_tweet(db, pid, twitter) }
      end
    rescue Exception => e
      puts [[e.message] + e.backtrace].join("\n")
      replies(db).each do |r|
        Util::Mongo.ensure_tweet_ancestry(db, r, twitter)
      end
    end
  end

  def ensure_conversations(db)
    lock = Redis::Lock.new(id,
                           :expiration => 1.minute,
                           :timeout => 1.minute)
    lock.lock do
      fetch_replies(db)
      ensure_tweets_ancestry(db)
    end
  end
end
