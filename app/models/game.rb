# encoding:utf-8
class Game < ActiveRecord::Base
  attr_accessible :args, :banner, :end_at, :guid, :rule, :stamp, :start_at, :status, :title, :winners, :wxdata
  
  def self.kanjia
    game = Game.find_by_stamp "KANJIA"
    
    unless game
      game = Game.new
      game.guid = WeixinHelper.guid
      game.wxdata = {}
      game.args = {
        "origin_price"=>768800,
        "current_price"=>768800,
        "discount"=>0
      }      
      game.winners = []
      game.start_at = Time.parse("2014-12-28 00:00:00 +0800")
      game.end_at = Time.parse("2015-01-08 23:59:59 +0800")
      game.status = "OPEN"
      game.stamp  = "KANJIA"          
      game.save!
    end
    
    game
  end
  
  def self.kanjia_iphone
    game = Game.find_by_stamp "KANJIA_IPHONE"
    
    unless game
      game = Game.new
      game.guid = WeixinHelper.guid      
      game.args = {
        "origin_price"=>688800,
        "current_price"=>688800,
        "discount"=>0
      }
      game.winners = []
      game.start_at = Time.parse("2015-01-05 00:00:00 +0800")
      game.end_at = Time.parse("2015-01-16 23:59:59 +0800")
      game.status = "OPEN"
      game.stamp  = "KANJIA_IPHONE"          
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
        "红蛋"=>[50,"Paul Frank钱包"],
        "黄蛋"=>[100, "COACH钱包"],
        "蓝蛋"=>[300, "Kate Spade单肩包"],
        "彩蛋"=>[500, "BURBERRY手提包"]
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
