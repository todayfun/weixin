class Fans < ActiveRecord::Base
  attr_accessible :city, :nickname, :openid, :sex, :subscribe_time
  
  def self.subscribe_by(openid)
    fans = Fans.find_by_openid openid
    return fans if fans
    
    fans = Fans.new
    fans.openid = openid
    json = WeixinHelper.query_userinfo(openid)
    return nil if json["nickname"].nil?
    
    fans.nickname = json["nickname"]
    fans.city = json["city"]
    fans.sex = json["sex"]
    fans.subscribe_time = json["subscribe_time"].to_i
    fans.save!
    
    fans
  end
  
  def self.save_by_userinfo(userinfo)
    openid = userinfo["openid"]
    return if openid.blank?
    
    fans = Fans.find_by_openid openid
    fans ||= Fans.new
    fans.openid = openid
    fans.nickname = userinfo["nickname"]
    fans.city = userinfo["city"]
    fans.sex = userinfo["sex"]    
    fans.save!
    
    fans
  end
end
