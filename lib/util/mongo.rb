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
    
    def self.capped_collection(name, size, *unique_cols)
      unless DB[name]
        begin
          DB.create_collection(name,
                             :capped => true,
                             :size => size) rescue DB[name]
          unique_cols.each do |col|
            DB[name].ensure_index([[col, 1]],
                                :background => true,
                                :unique => true)
          end
          Rails.logger.info("Created capped collection #{name} of size #{size}, unique cols : #{unique_cols.inspect}")
        rescue
          DB[name]
        end
      end
      DB[name]
    end

    def self.user_replies_collection(user)
      capped_collection("replies_#{user.twauth.uid}", CAPPED_COLLECTION_SIZE_REPLIES, :id)
    end

    def self.tweets_collection
      capped_collection("tweets", CAPPED_COLLECTION_SIZE_TWEETS, :id)
    end

    def self.tweet(id)
      tweets_collection.find(:id => id).first
    end

    def self.cache_tweet(tweet)
      return if tweet(tweet.id)
      tweets_collection.insert(tweet.to_hash)
      Rails.logger.info("Added tweet #{tweet.id} to tweets")
    end
  end
end
