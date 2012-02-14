class HomeController < ApplicationController
  def index
    @user = User.find(session[:user_id]) rescue nil
  end

  def conversations 
    user = User.find(session[:user_id]) rescue nil

    if user.nil?
      render :nothing => true
      return
    end

    twitter = user.twitter_client
    user.ensure_conversations
    
    tweets = {}
    root_ids = Set.new
    
    user.replies.each do |tweet|
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
            mt = Util::Mongo.ensure_tweet(pid, twitter)
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
    render :json => roots.to_json
  end
end
