#encoding:utf-8
class CaidanController < ApplicationController
  layout "caidan"  
  @@subscribe_url = "http://mp.weixin.qq.com/s?biz=MzA3OTg5MzMxNg==&mid=204493713&idx=1&sn=0b03c8ebbb9303882d0208c992a48c95#rd"

  def wxdata
    wxdata = {
    :title=>"幸福彩蛋大家砸，砸碎大奖拿回家，蛋蛋有奖，门槛低，拿奖易！",
    :img_url=>url_for(:controller=>"mac.jpg"),
    :link=>url_for(:action=>"gameview",:game=>Game.caidan.guid),
    :desc=>"幸福彩蛋等你来砸，蛋蛋有奖，蛋砸碎了蛋里的宝贝就是你的啦！快召集你的蛋友来帮忙砸蛋吧！"
    }
    
    wxdata
  end  
  
  def reset
    cookies[:openid] = nil    
    cookies[:from_weixin] = nil
    cookies[:friend] = nil    
    
    respond_to do |format|
      format.html {redirect_to @@subscribe_url}
    end
  end

=begin
文字内容：请谨慎选择蛋的颜色，你只有一次发起砸蛋活动的权利哦，看看你能召集多少蛋友来帮你砸蛋，再合理选择蛋的颜色哦！
选择要砸的蛋种类，蛋底下的文字根据选择蛋的不同，显示不同内容
红蛋——耐砸数：30次   奖品：50元手机充值卡或100元天使商城现金券
橙蛋——耐砸数：50次   奖品：小米16000毫安充电宝或200元天使商城现金券
黄蛋——耐砸数：100次   奖品：三星Gear V700智能手表或500元天使商城现金券
绿蛋——耐砸数：150次   奖品：红米手机Note增强版或1000元天使商城现金券
=end    
  def gameview
    @game = Game.find_by_guid(params[:game]) || Game.caidan
    redirect_url = nil
    
    label = %{抡圆了锤子先砸一下}
    
    title = ""
    
    links = %{分享到朋友圈}
    
    tair = %{活动规则 奖品展示 幸福的人}
    
    if redirect_url
      respond_to do |format|
        format.html {redirect_to redirect_url}
      end
    else
      respond_to do |format|
        format.html
      end
    end
  end
  
  
  def launchgame
    @game = Game.find_by_guid(params[:game]) || Game.caidan
    
    notice = %{一个ID只能发起一次活动}
    notcie = %{呜呜，好硬的蛋，一下子砸不碎，还需砸**下才能砸碎哦，快邀请你的蛋友来帮你砸蛋吧，蛋砸碎了蛋里的宝贝就是你的啦！}
        
    respond_to do |format|
      format.html {redirect_to redirect_url}
    end    
  end
  
=begin
我的砸蛋记录
=end  
  def playview
    @play = Play.find_by_guid(params[:play])
    @game = Game.find_by_guid(@play.game_guid)
    
    # by friend
    label = %{帮TA砸一下|你已经帮他砸过啦}
    title = %{已咋xx次，还差24次就砸碎啦，加油！}
    links = %{找朋友帮TA砸 我也要咋幸福彩蛋免费拿大奖}    
    tair = %{活动规则 奖品展示 幸福的人}
    
    # by owner
    label = %{自己砸一下|你已经砸过了}
    title = %{已咋xx次，还差24次就砸碎啦，加油！}
    links = %{找朋友帮我砸 我的砸蛋记录}
    tair = %{活动规则 奖品展示 幸福的人}
    
    if redirect_url
      respond_to do |format|
        format.html {redirect_to redirect_url}
      end
    else
      respond_to do |format|
        format.html
      end
    end
  end
  
=begin
1、一个ID在活动期间，帮不同人砸蛋的次数，累计不能超过5次。
2、一次活动中，比如，A发起的砸蛋活动，只能帮A砸一次。
3、同一个ID，只能发起一次活动，只能自己砸一次。
4、如果超过了砸蛋次数，则弹出窗口提示：“对不起，你的5次砸蛋权已经用完啦，换个手机和微信再来参加吧！”
=end  
  def doplay
    @play = Play.find_by_guid(params[:play])
    @game = Game.find_by_guid(@play.game_guid)
    
    # by owner
    notice = %{呜呜，好硬的蛋，一下子砸不碎，还需砸**下才能砸碎哦，快邀请你的蛋友来帮你砸蛋吧，蛋砸碎了蛋里的宝贝就是你的啦！}
    
    # by friend
    notice = %{感谢恩人赏了一锤，离免费大奖又近了一步，快去留个言邀功吧，点击确定你也可以参加“幸福彩蛋大家砸，砸碎大奖拿回家”活动，蛋蛋有奖！}
    
    notice = %{你已经帮TA砸过一次啦，不能再砸啦！邀请其他小伙伴来帮忙砸吧。心动不如行动，快来参加“幸福彩蛋大家砸，砸碎大奖拿回家”活动，蛋蛋有奖，蛋砸碎了蛋里的宝贝就是你的啦！}
    
    
    
    respond_to do |format|
      format.html {redirect_to redirect_url}
    end
  end
    
  def dokanjia
    game = Game.caidan
    redirect_url = url_for(:action=>"gameview", :game=>game.guid)
    if params[:from_weixin] == "zhongqi"
      cookies[:from_weixin] = game.guid
    end
    
    if !cookies[:doplay_url].blank?
      redirect_url = cookies[:doplay_url]      
    end
    
    respond_to do |format|
      format.html {redirect_to redirect_url}
    end
  end
  
  def playhistory
    @play = Play.find_by_guid params[:play]
    @game = Game.find_by_guid(@play.game_guid)
    
    @game_url = url_for(:action=>"gameview",:game=>@game.guid)
    @wxdata = wxdata()
    @wxdata[:link] = @game_url
    
    respond_to do |format|
      format.html
    end
  end
  
  def rule
    @game = Game.find_by_guid params[:game] || Game.caidan
    
    @game_url = url_for(:action=>"gameview",:game=>@game.guid)
    @wxdata = wxdata()
    @wxdata[:link] = @game_url
    
    respond_to do |format|
      format.html
    end
  end
  
  def topn
    @game = Game.find_by_guid params[:game] || Game.caidan
    
    @game_url = url_for(:action=>"gameview",:game=>@game.guid)
    @wxdata = wxdata()
    @wxdata[:link] = @game_url
    
    respond_to do |format|
      format.html
    end
  end
  
  def has_played?(play,openid)   
    friends = play.friends    
    key = "#{openid},#{Date.today.to_s}"
    friends.include?(key)
    #false
  end
  
  def has_subscribed?
    if !cookies[:from_weixin].blank?
      true
    else
      false
    end    
  end
end
