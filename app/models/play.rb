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
end
