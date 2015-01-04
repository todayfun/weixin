# encoding:utf-8
class Game < ActiveRecord::Base
  attr_accessible :args, :banner, :end_at, :guid, :rule, :stamp, :start_at, :status, :title, :winners, :wxdata
  
  def self.kanjia
    game = Game.find_by_stamp "KANJIA"
    
    unless game
      game = Game.new
      game.guid = WeixinHelper.guid
      game.title = "一刀砍掉1500元，砍到0元MacBook就是你的啦，快召集朋友来帮你砍吧。"
      game.banner = "http://42.121.128.45/mac.jpg"
      game.wxdata = {}
      game.args = {
        "origin_price"=>768800,
        "current_price"=>768800,
        "discount"=>0
      }
      game.rule = "本次活动的奖品MacBook Air，为大陆行货，全新未拆封，有发票，全国联保。"
      game.winners = []
      game.start_at = Time.parse("2014-12-28 00:00:00 +0800")
      game.end_at = Time.parse("2015-01-08 23:59:59 +0800")
      game.status = "OPEN"
      game.stamp  = "KANJIA"          
      game.save!
    end
    
    game
  end
  
  def self.caidan
    game = Game.find_by_stamp "CAIDAN"
    
    unless game
      game = Game.new
      game.guid = WeixinHelper.guid
      game.args = {
        "origin_price"=>768800,
        "current_price"=>768800,
        "discount"=>0
      }
      game.winners = []
      game.start_at = Time.now
      game.end_at = 1.week.from_now
      game.status = "OPEN"
      game.stamp  = "CAIDAN"          
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
