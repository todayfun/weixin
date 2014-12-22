# encoding:utf-8
class Game < ActiveRecord::Base
  attr_accessible :args, :banner, :end_at, :guid, :rule, :stamp, :start_at, :status, :title, :winners, :wxdata
  
  def self.default
    game = Game.first
    
    unless game
      game = Game.new
      game.guid = WeixinHelper.guid
      game.title = "kanjia iphone6"
      game.banner = "http://p0.55tuanimg.com/static/goods/mobile/2014/07/03/13/0153b4cdcf4dba2f9d7b94d6681914d9_3.jpg"
      game.wxdata = {
      "img_url"=> "http://p0.55tuanimg.com/static/goods/mobile/2014/07/03/13/0153b4cdcf4dba2f9d7b94d6681914d9_3.jpg",
      "link"=> "http://42.121.128.45/kanjia/kanjia",
      "desc"=> "description kanjia iphone6",
      "title"=> "kanjia iphone6"
      }
      game.args = {
        "origin_price"=>6000.0,        
      }
      game.rule = "共10台，先到先得"
      game.winners = []
      game.start_at = Time.now
      game.end_at = 1.week.from_now
      game.status = "OPEN"
      game.stamp  = "TEST"          
      game.save!
    end
    
    game
  end
  
  def args
    ActiveSupport::JSON.decode(read_attribute(:args)||{}.to_json)
  end
  
  def args=(args)
    write_attribute :args,args.to_json
  end
  
  def winners
    ActiveSupport::JSON.decode(read_attribute(:winners)||[].to_json)
  end
  
  def winners=(winners)
    write_attribute :winners,winners.to_json
  end
  
  def wxdata
    ActiveSupport::JSON.decode(read_attribute(:wxdata)||{}.to_json)
  end
  
  def wxdata=(wxdata)
    write_attribute :wxdata,wxdata.to_json
  end
  
end
