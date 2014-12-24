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
end
