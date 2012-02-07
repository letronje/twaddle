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
    
    def self.user_replies_collection(db, user)
      capped_collection(db, "replies_#{user.twauth.uid}", 10.megabytes)
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

    def self.tweet_to_hash(tweet)
      txt = tweet["text"]

      # loop do
      #   txt.lstrip!
      #   ntxt = txt.gsub(/^@[a-zA-Z_]+/, '')
      #   break if ntxt == txt
      #   txt = ntxt
      # end

      {
        :id => tweet["id"],
        :txt => txt,
        :pid => tweet["in_reply_to_status_id"],
        :name => tweet["user"]["name"],
        :nick => tweet["user"]["screen_name"],
        :at => tweet["created_at"],
        :uimg => tweet["user"]["profile_image_url"],
        :wt => 0,
        :mid => 0
      }
    end
  end
end
