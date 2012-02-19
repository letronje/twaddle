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

    user.wait_for_conversations
    
    roots = conversation_roots(user)
    render :json => roots.to_json
  end

  def get_root_and_children(tweet, cache, twitter)
    t = Util::Twitter.tweet_to_hash(tweet)
    children_ids = Set.new
    
    root_id = loop do
      id = t[:id]
      pid = t[:pid]
      
      cache[id] ||= t
      
      if pid.nil?
        break id
      else
        children_ids << id
        t = cache[pid]
        unless t
          mt = Util::Twitter.ensure_tweet(pid, twitter)
          if mt
            t = Util::Twitter.tweet_to_hash(mt)
          else
            break id
          end
        end
      end
    end

    [root_id, children_ids]
  end

  def update_root(root_id, children_ids, cache)
    root = cache[root_id]
    children = cache.values_at(*children_ids)
    
    root[:c] = (root[:c] || Set.new).merge(children)
    root[:wt] = [root[:wt], children_ids.size].max
    root[:mid] = children.max_by { |c| c[:id] }[:id]
  end
  
  def conversation_roots(user)
    twitter = user.twitter_client

    cache = {}
    root_ids = Set.new
    
    user.replies.each do |tweet|
      root_id, children_ids = get_root_and_children(tweet, cache, twitter)
      update_root(root_id, children_ids, cache)
      root_ids << root_id
      Rails.logger.info("Found root tweet #{root_id} for user #{user.id}, children(#{children_ids.size}) : #{children_ids.inspect}")
    end

    root_ids.sort{|a, b| b <=> a}.map{|rid| cache[rid]}
  end

  private :conversation_roots
end
