# encoding:utf-8
class Game < ActiveRecord::Base
  attr_accessible :args, :banner, :end_at, :guid, :rule, :stamp, :start_at, :status, :title, :winners, :wxdata
  
  def self.default
    game = Game.first
    
    unless game
      game = Game.new
      game.guid = WeixinHelper.guid
      game.title = "一刀砍掉1500元，砍到0元MacBook就是你的啦，快召集朋友来帮你砍吧。"
      game.banner = "http://42.121.128.45/images/mac.jpg"
      game.wxdata = {
      "img_url"=> "http://42.121.128.45/images/mac.jpg",
      "link"=> "http://42.121.128.45/kanjia/kanjia",
      "desc"=> "免费召唤MacBook Air，先自砍一刀，再邀请小伙伴们来帮你砍价，砍到0元，宝贝就是你的啦！比比谁的朋友多，呼朋唤友，齐心合力，免费大奖拿回家！还等什么？",
      "title"=> "一刀砍掉1500元，砍到0元MacBook就是你的啦，快召集朋友来帮你砍吧。"
      }
      game.args = {
        "origin_price"=>768800,
        "current_price"=>768800,
        "discount"=>0
      }
      game.rule = "本次活动的奖品MacBook Air，为大陆行货，全新未拆封，有发票，全国联保。"
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
