class HomeController < ApplicationController
  def index
    @user = User.find(session[:user_id]) rescue nil
  end

  def tweets
    @user = User.find(session[:user_id]) rescue nil
    db = Mongo::Connection.new.db("twonversations")
    twitter = @user.twitter_client
    
    replies = {}
    ancestors = {}

    tweets = {}
    root_ids = Set.new
    
    @user.replies(db).each do |tweet|
      children_ids = Set.new

      t = Util::Mongo.tweet_to_hash(tweet)
      
      root_id = loop do
        id = t[:id]
        pid = t[:pid]

        tweets[id] ||= t
        
        if pid.nil?
          break id
        else
          children_ids << id
          t = tweets[pid]
          unless t
            mt = Util::Mongo.ensure_tweet(db, pid, twitter)
            ap mt
            t = Util::Mongo.tweet_to_hash(mt)
          end
        end
      end

      root_ids << root_id

      root = tweets[root_id]
      children = children_ids.map{|cid| tweets[cid] }

      root[:c] = (root[:c] || Set.new).merge(children)
      root[:wt] = [root[:wt], children_ids.size].max
      root[:mid] = children.max_by { |c| c[:id] }[:id]
    end

    roots = root_ids.sort{|a, b| b <=> a}.map{|rid| tweets[rid]}
    @data = roots
  end
end
