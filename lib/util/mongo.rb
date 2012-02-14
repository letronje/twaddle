require 'action_view'

include ActionView::Helpers::DateHelper

module Util
  class Mongo

    CAPPED_COLLECTION_SIZE_REPLIES = 10.megabytes
    CAPPED_COLLECTION_SIZE_TWEETS = 20.megabytes

    DBNAME = "twaddle"
    CONN = ::Mongo::Connection.new
    DB = CONN.db(DBNAME)

    def self.connection
      CONN
    end
    
    def self.capped_collection(name, size)
      DB.create_collection(name,
                           :capped => true,
                           :size => size) rescue DB[name]
      DB[name]
    end

    def self.user_replies_collection(user)
      capped_collection("replies_#{user.twauth.uid}", CAPPED_COLLECTION_SIZE_REPLIES)
    end

    def self.tweets_collection
      capped_collection("tweets", CAPPED_COLLECTION_SIZE_TWEETS)
    end

    def self.ensure_tweet(id, twitter)
      coll = tweets_collection
      tweet = coll.find(:id => id).first
      if tweet.nil?
        coll.insert(twitter.status(id).to_hash)
        tweet = coll.find(:id => id).first
      end
      tweet
    end

    def self.ensure_tweets(ids, twitter)
      p = Util::Pool.new(10)
      
      ids.each do |id|
        p.schedule do 
          ensure_tweet(id, twitter)
        end
      end

      p.shutdown
    end
    
    def self.ensure_tweet_ancestry(tweet, twitter)
      loop do
        parent_id = tweet["in_reply_to_status_id"]
        break if parent_id.nil?
        begin
          tweet = ensure_tweet(parent_id, twitter)
        rescue Exception  => e
          puts e.message + "\n" + e.backtrace.join("\n")
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
