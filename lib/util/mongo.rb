module Util
  class Mongo
    def self.capped_collection(db, name, size)
      unless db.collection_names.include? name
        db.create_collection(name,
                             :capped => true,
                             :size => size)
      end
      db[name]
    end
    
    def self.user_tweets_collection(db, user)
      capped_collection(db, "tweets_#{user.twauth.uid}", 10.megabytes)
    end

    def self.tweets_collection(db)
      capped_collection(db, "tweets", 20.megabytes)
    end

    def self.ensure_tweet(db, id, twitter)
      coll = tweets_collection(db)
      tweet = coll.find(:id => id).first
      if tweet.nil?
        coll.insert(twitter.status(id).to_hash)
        tweet = coll.find(:id => id).first
      end
      tweet
    end
    
    def self.ensure_tweet_ancestry(db, tweet, twitter)
      loop do
        parent_id = tweet["in_reply_to_status_id"]
        break if parent_id.nil?
        begin
          tweet = ensure_tweet(db, parent_id, twitter)
        rescue Exception  => e
          puts e.message + "\n" + e.backtrace.join("\n")
          break
        end
      end
    end
  end
end
