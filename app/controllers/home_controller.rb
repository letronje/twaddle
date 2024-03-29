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

  def get_root_and_children(tweet, cache, children_roots, twitter)
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
        
        root_id = children_roots[pid]
        if root_id
          break root_id
        end
                
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

  def print_roots(root_ids, cache)
    total_c = root_ids.reduce(0) do |sum, root_id|
      sum + cache[root_id][:c].size
    end
    Rails.logger.info "TOTAL(#{root_ids.size + total_c}), ROOTS(#{root_ids.size}), CHILDREN(#{total_c})"
    # root_ids.each do |root_id|
    #   root = cache[root_id]
    #   children_ids = root[:c].map{|c| c[:id]}
    #   Rails.logger.info root_id.to_s + " => " + children_ids.inspect
    # end
  end
  
  def conversation_roots(user)
    twitter = user.twitter_client

    cache = {}
    children_roots = {}
    root_ids = Set.new
    
    user.replies.each do |tweet|
      Rails.logger.info "\n\nFinding root tweets for #{tweet['id']}"
      root_id, children_ids = get_root_and_children(tweet, cache, children_roots, twitter)
      children_ids.each  { |cid| children_roots[cid] = root_id}
      update_root(root_id, children_ids, cache)
      root_ids << root_id
      print_roots(root_ids, cache)
      #Rails.logger.info("\tFound root tweet #{root_id} for user #{user.id}, children(#{children_ids.size}) : #{children_ids.inspect}")
    end

    root_ids.sort{|a, b| b <=> a}.map{|rid| cache[rid]}
  end

  private :conversation_roots
end
