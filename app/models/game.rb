class Game < ActiveRecord::Base
  attr_accessible :args, :banner, :end_at, :guid, :rule, :stamp, :start_at, :status, :title, :winners, :wxdata
  
  def args
    ActiveSupport::JSON.decode(self.read_attribute(:args)||{}.to_json)
  end
  
  def args=(args)
    self.write_attribute :args,args.to_json
  end
  
  def winners
    ActiveSupport::JSON.decode(self.read_attribute(:winners)||[].to_json)
  end
  
  def winners=(winners)
    self.write_attribute :winners,winners.to_json
  end
  
  def wxdata
    ActiveSupport::JSON.decode(self.read_attribute(:wxdata)||{}.to_json)
  end
  
  def wxdata=(wxdata)
    self.write_attribute :wxdata,wxdata.to_json
  end
  
end
