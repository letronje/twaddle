module Util
  class Twitter
    def self.ensure_tweet(id, twitter)
      begin
        #Rails.logger.info("Ensuring tweet #{id}")
        tweet = Util::Mongo.tweet(id)
        if tweet.nil?
          Util::Mongo.cache_tweet(twitter.status(id))
          #Rails.logger.info("Fetched tweet #{id}")
        end
        Util::Mongo.tweet(id)
      rescue Exception => e
        Rails.logger.error ([e.message] + e.backtrace).join("\n")
        nil
      end
    end

    def self.ensure_tweets(ids, twitter)
      Rails.logger.info("Ensuring tweets #{ids.inspect}")
      p = Util::Pool.new(10)
      
      ids.each do |id|
        p.schedule do 
          ensure_tweet(id, twitter)
        end
      end

      p.shutdown
    end
    
    def self.ensure_tweet_ancestry(tweet, twitter)
      Rails.logger.info("Ensuring ancestors for tweet #{tweet['id']}")
      loop do
        parent_id = tweet["in_reply_to_status_id"]
        break if parent_id.nil?
        begin
          tweet = ensure_tweet(parent_id, twitter)
        rescue Exception  => e
          Rails.logger.error e.message + "\n" + e.backtrace.join("\n")
          break
        end
      end
    end

    def self.tweet_to_hash(tweet)
      txt = tweet["text"]

      at = tweet["created_at"]
      at_time = Time.zone.parse(at)

      today = ((Time.now - at_time) <= 24.hours)
      last_hour  = (Time.now - at_time) <= 1.hours
      
      {
        :id => tweet["id"],
        :txt => txt,
        :pid => tweet["in_reply_to_status_id"],
        :name => tweet["user"]["name"],
        :nick => tweet["user"]["screen_name"],
        :ago => distance_of_time_in_words_to_now(at_time),
        :uimg => tweet["user"]["profile_image_url"],
        :wt => 0,
        :mid => 0,
        :today => today,
        :last_hour => last_hour
      }
    end
  end
end
    
