class Play < ActiveRecord::Base
  attr_accessible :args, :end_at, :friends,:friend_plays, :game_guid, :guid, :owner, :stamp, :start_at, :status,:score
  
  def friends
    ActiveSupport::JSON.decode(self.read_attribute(:friends)||[].to_json)
  end
  
  def friends=(friends)
    write_attribute :friends,friends.to_json
  end
  
  def friend_plays
    ActiveSupport::JSON.decode(read_attribute(:friend_plays)||[].to_json)
  end
  
  def friend_plays=(plays)
    write_attribute :friend_plays,plays.to_json
  end
  
  def args
    ActiveSupport::JSON.decode(read_attribute(:args)||{}.to_json)
  end
  
  def args=(args)
    write_attribute :args,args.to_json
  end
  
  def self.launchgame(openid,game)
    play = Play.where(:game_guid=>game.guid, :owner=>openid).first
    if play.nil?
      play = Play.new
      play.guid = WeixinHelper.guid
      play.game_guid = game.guid
      play.owner = openid
      play.score = 0
      play.args = game.args
      play.friends = []
      play.friend_plays = []
      play.start_at = Time.now
      play.end_at = game.end_at
      play.stamp = game.stamp
      play.status = game.status
      
      if block_given?
        yield play
      end
      
      play.save
    end
    
    play
  end
      
  # [2,2,3,4,4,3,2,2]
  def self.seed_kanjia_players()
    stamp = "SEED_KANJIA"
    game = Game.kanjia
    from_date = "2014-12-28"
    days = 11 # 日期从2014-12-28-2015-01-07共11天
    self.do_seed_kanjia_players(game,stamp,from_date,days)
  end
  
  def self.seed_kanjia_players_iphone()
    stamp = "SEED_KANJIA_IPHONE"
    game = Game.kanjia_iphone
    from_date = "2015-01-05"
    days = 12 # 日期从2015-01-05-2015-01-16共12天
    self.do_seed_kanjia_players(game,stamp,from_date,days)
  end
  
  def self.do_seed_kanjia_players(game,stamp,from_date,days)
    cnt = Play.where(:game_guid=>game.guid,:stamp=>stamp).count
    return cnt if cnt > 50
    
    Play.where(:game_guid=>game.guid,:stamp=>stamp).delete_all
            
    t1 = Time.parse(from_date)   
    one_day = 1.day.to_i    
    
    d = 1
    sum = 0 
    while(d <= days) do
      # 每天生产50-100个
      cnt = 50 + rand(50)      
      i = 1
      t_delta = one_day*d
      
      while(i<=cnt) do
        play = Play.new
        play.guid = WeixinHelper.guid
        play.game_guid = game.guid
        play.owner = WeixinHelper.guid
             
        args = game.args
        discount = (args["origin_price"]*0.1).to_i + rand(args["origin_price"]*0.2)
        args["current_price"] = args["origin_price"] - discount
        args["discount"] = args["origin_price"] - args["current_price"]
        play.args = args
        play.score = args["discount"]
        
        play.friends = []
        play.friend_plays = []
        play.start_at = t1 + rand(t_delta)
        play.end_at = game.end_at
        play.stamp = stamp
        play.status = game.status

        if block_given?
          yield play
        end

        play.save

        i += 1
      end
      
      d += 1
      sum += cnt
    end        
    
    sum
  end
  
  # 设置参加砍价的人数
  def self.seed_count()    
    seed_cnt = [20000,20000,30000,40000,40000,30000,20000,20000,5000]
    from_date = "2014-12-31"
    
    self.do_seed_count(from_date, seed_cnt)
  end
  
  # 设置参加砍价的人数
  def self.seed_count_iphone()
    seed_cnt = [20000,20000,30000,40000,40000,30000,20000,20000,5000]
    from_date = "2015-01-05"
    self.do_seed_count(from_date, seed_cnt)
  end
  
  def self.do_seed_count(from_date,seed_cnt)
    t0 = Time.parse(from_date).to_i    
    t = Time.now.to_i
    
    add_cnt = if t > t0
      one_day = 1.day.to_i
      d = (t-t0)/one_day
      t_delta = (t-t0) - d * one_day
      seed_cnt[0,d].sum + (seed_cnt[d]||0) * t_delta / one_day
    else
      0
    end
    
    add_cnt
  end
  
  # [3,7,10,13,16,19,22,25]
  # 设置看到0的人数
  def self.seed_kanjia_winners()
    stamp = "SEED_KANJIA"
    game = Game.kanjia
    from_date = "2014-12-31"
    winner_cnt = [3,7,10,13,16,19,22,24,25]
    
    self.do_seed_kanjia_winners(game,stamp,from_date,winner_cnt)
  end
  
  def self.seed_kanjia_winners_iphone()
    stamp = "SEED_KANJIA_IPHONE"
    game = Game.kanjia_iphone
    from_date = "2015-01-06"
    winner_cnt = [3,7,10,13,16,19,22,24,25]
    
    self.do_seed_kanjia_winners(game,stamp,from_date,winner_cnt)
  end
  
  def self.do_seed_kanjia_winners(game,stamp,from_date,winner_cnt)
    t0 = Time.parse(from_date).to_i  
    t = Time.now    
    one_day = 1.day.to_i
    plays = Play.where("game_guid='#{game.guid}' and stamp='#{stamp}' and start_at < '#{t.utc}'").order("score desc").limit(50)
        
    closed = 0
    hashed = {}
    plays.each do |play|      
      args = play.args
      if args["current_price"]==0
        closed += 1
      else
        discount = rand(args["current_price"]*0.7)
        args["current_price"] = args["current_price"] - discount
        args["discount"] = args["origin_price"] - args["current_price"]
        play.args = args
        play.score = args["discount"]
        
        t_delta = (t.to_i-play.start_at.to_i)*100/one_day
        p_delta = args["discount"]*100/args["origin_price"]
        delta = t_delta + p_delta*4
        hashed[delta] = play
      end            
    end
    
    d = (t.to_i - t0)/one_day
    return if d < 0
    
    need_cnt = (winner_cnt[d]||0)
    cnt = (need_cnt - closed) * (t.to_i - t0) / ((d+1)*one_day)
    Rails.logger.info("day:#{d},need:#{need_cnt},current:#{closed},add:#{cnt}")
    if cnt > 0
      keys = hashed.keys.sort{|a,b| b<=>a}[0,cnt]
      keys.each do |key|
        play = hashed[key]
        args = play.args
        play.score = args["origin_price"]
        args["discount"] = args["origin_price"]
        args["current_price"] = 0
        play.args = args        
        play.end_at = t
        play.status = "CLOSED"
      end
      
      plays.each do |play|
        play.save
      end
    end
  end
end
