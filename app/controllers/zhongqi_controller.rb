# encoding:utf-8
class ZhongqiController < ApplicationController
  layout false  
  
  def kanjia
    # get current command    
    @label = ""
    @links = []
    @title = ""
    @share_url = ""   
    @input_nickname = false
    
    redirect_url = nil
    cmd = params[:cmd]||"gameview"    

    # gameview 
    # link:kanjia?game=guid&cmd=gameview
    # click play: weixin_auth(kanjia?game=guid&cmd=gamelaunch)
    # share: kanjia?game=guid&cmd=gameview
    if "gameview"==cmd
      openid = get_openid()
      game = Game.find_by_guid(params[:game]) || Game.default
      if game
        play = Play.where(:game_guid=>game.guid,:owner=>openid).first
        if play && openid
          @title = "已经创建了游戏，直接进入"
          redirect_url = url_for(:play=>play.guid,:cmd=>"playview")
        else
          if openid
            @label = view_context.link_to("参与砍价",url_for(:game=>game.guid,:cmd=>"gamelaunch"))
          else
            @label = input_nickname(game.guid)
          end
          @title = "原始价格"          
          @share_url = url_for(:game=>game.guid,:cmd=>"gameview")
          @links = [view_context.link_to("查看砍价规则",url_for(:action=>"rule",:game=>game.guid)),view_context.link_to("查看砍价排行",url_for(:action=>"topn",:game=>game.guid))]
        end
      else
        @label = "#{cmd} fail: cant found game"
      end

    # launchgame
    # link: kanjia?game=guid&cmd=gamelaunch
    # subscribe?：redirect_to weixin_auth(kanjia?play=guid&cmd=playview)
    # unsubscribe?：redirect_to subscribe
    elsif "gamelaunch"==cmd
      openid = get_openid()
      unless openid
        openid = set_openid(params[:nickname])
      end
      
      if openid
        if has_subscribed?
          game = Game.find_by_guid(params[:game])
          if game
            play = Play.launchgame(openid,game)

            @label = "game launched!"
            redirect_url = url_for(:play=>play.guid,:cmd=>"playview")
          else
            @label = "#{cmd} fail: cant found game"
          end
        else
          @label = "#{cmd} fail: 还没订阅公众号"
          redirect_url = url_for(:action=>"subscribe")          
        end
      else
        @label = "请输入正确的微信昵称"
        flash[:notice] = "请输入正确的微信昵称"
        redirect_url = url_for(:game=>params[:game],:cmd=>"gameview")
      end

    # playview
    # link: weixin_auth(kanjia?play=guid&cmd=playview)
    # doplay: weixin_auth(kanjia?play=guid&cmd=doplay)
    # share: weixin_auth(kanjia?play=guid&cmd=playview)  
    elsif "playview"==cmd
      openid = get_openid()
      play = Play.find_by_guid params[:play]
      if play        
        @title = "当前战绩:#{play.args.to_json}"
        @share_url = url_for(:play=>play.guid,:cmd=>"playview")
        
        if openid == play.owner
          if has_played?(play,openid)
            @label = "您已经砍过了!"
            @links = ["找朋友帮我砍",view_context.link_to("我的砍价列表",url_for(:action=>"play_history",:play=>play.guid))]
          else
            @label = view_context.link_to("自砍一刀",url_for(:play=>play.guid,:cmd=>"doplay"))
            @links = [view_context.link_to("查看砍价规则",url_for(:action=>"rule",:game=>play.game_guid)),view_context.link_to("查看砍价排行",url_for(:action=>"topn",:game=>play.game_guid))]
          end            
        else
          friend = get_friend()
          if has_played?(play,friend)
            @label = "您已经砍过了"
            @links = [view_context.link_to("我也要0元拿",url_for(:game=>play.game_guid,:cmd=>"gameview"))]
          else
            @label = view_context.link_to("帮TA砍价",url_for(:play=>play.guid,:cmd=>"doplay"))
            @links = [view_context.link_to("我也要0元拿",url_for(:game=>play.game_guid,:cmd=>"gameview"))]
          end
        end        
      else
        @label = "#{cmd} fail: cant found play"
      end

    # playview
    # link: weixin_auth(kanjia?play=guid&cmd=playview)
    # doplay: weixin_auth(kanjia?play=guid&cmd=doplay)
    # share: weixin_auth(kanjia?play=guid&cmd=playview)    
    elsif "doplay"==cmd
      openid = get_openid()||get_friend()
      play = Play.find_by_guid(params[:play])
      if play
        @label = "do play"
        msg = doplay(play,openid)
        flash[:notice] = msg
        redirect_url = url_for(:play=>play.guid,:cmd=>"playview")
      else
        @label = "#{cmd} fail: cant found play"
      end
    else
      @label = "invalid cmd"
    end
    
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
  
  # link: rule?game=guid
  def rule
    respond_to do |format|
      format.html {render :text=>"rule page for #{params[:game]}"}
    end
  end
  
  # link: topn?game=guid
  def topn
    plays = Play.where(:game_guid=>params[:game])
    
    if !plays.empty?
      topN = plays.map do |play|
        "#{play.owner},#{play.args["origin_price"]},#{play.args["current_price"]},#{play.args["discount"]}"
      end.join("<br/>")
    else
      topN = "您是第一个游戏玩家，加油！"
    end
        
    respond_to do |format|
      format.html {render :text=>topN.html_safe}
    end
  end
  
  def subscribe
    dosubscribe!
    
    respond_to do |format|
      format.html
    end
  end
  
  # /play_history?play=guid
  def play_history
    play = Play.find_by_guid params[:play]
    if play
      history = play.friend_plays.map{|r| r.join(',')}.join("<br/>")
    else
      history = "还没有砍价记录"
    end
    respond_to do |format|
      format.html {render :text=>history.html_safe}
    end
  end
  
  def get_openid
    cookies[:openid]
    cookies[:openid].blank? ? nil : cookies[:openid]
  end
  
  def set_openid(openid)
    cookies[:openid] = openid.blank?  ? nil : openid
  end
    
  def get_friend
    friend = cookies[:friend]
    unless friend.blank?
      friend = WeixinHelper.guid
      cookies[:friend] = friend
    end
  
    friend
  end
  
  def has_subscribed?
    cookies[:subscribed_by] == get_openid
  end
  
  def dosubscribe!
    openid = get_openid
    cookies[:subscribed_by] = openid unless openid.blank?
  end
  
=begin
首次自己砍价数值随机，范围1000-2000；
第2次到第6次，别人帮你砍价，数值随机，范围100-200；
第7次到第16次，别人帮你砍价，数值随机，范围10-100；
第17次到第66次，别人帮你砍价，数值随机，范围10-20
第67次到第166次，别人帮你砍价，数值随机，范围5-10
第167次到第366次，别人帮你砍价，数值随机，范围1-5
第367次到第966次，别人帮你砍价，数值随机，范围0-1  最小单位分
第967次到第1766次，别人帮你砍价，数值随机，范围0-0.1  最小单位分
第1767次到第2500次，别人帮你砍价，数值随机，范围0-0.01元 
超过2500次，系统提示，对不起，由于您存在作弊行为，取消您此次活动的资格。
=end  
  def doplay(play,openid)
    msg = ""
    if has_played?(play,openid)
      msg = "您已经砍过价了!"      
    elsif play.status == "CLOSED"
      msg = "活动已经结束，欢迎再来!"
    else
      friends = play.friends
      friend_plays = play.friend_plays
      args = play.args
      args["current_price"] ||= args["origin_price"]
      cnt = friends.size

      if cnt >= 2000
        msg = "砍价超过了2000次，还没有砍到0元，挑战失败"        
      else
        # 以分为单位，变成整数运算
        discount = case cnt
        when 0
          100000+rand(100000) # 1000-2000
        when 2..6
          10000+rand(10000) # 100-200
        when 7..16
          1000+rand(9000) # 10-100
        when 17..66
          1000+rand(1000) # 10-20
        when 67..166
          500+rand(500) # 5-10
        when 167..366
          100+rand(400) # 1-5
        when 367..966
          10+rand(90) # 0.1-1
        when 967..2000
          1+rand(9) # 0.01-0.1
        else
          0
        end

        now = Time.now
        key = "#{openid}"
        if args["current_price"] > discount
          args["current_price"] -= discount
        else
          discount = args["current_price"]
          args["current_price"] = 0
          play.status = "CLOSED"
          play.end_at = now
        end

        args["discount"] = args["origin_price"] - args["current_price"]    
        friend_plays << [openid,discount,now]
        friends << key
        msg = "砍掉了#{discount/100.0}元！"

        play.args = args
        play.friends = friends
        play.friend_plays = friend_plays
        play.save
      end
    end
    
    msg
  end
  
  def has_played?(play,openid)   
    friends = play.friends    
    key = "#{openid}"
    friends.include?(key)
    false
  end
  
  def input_nickname(game_guid)
    html = view_context.form_tag "/zhongqi/kanjia?game=#{game_guid}&cmd=gamelaunch" do
      inner = %{
    <div class="field">
      <label>请输入微信昵称：</label>
      <input name="nickname" size="30" type="text">
    </div>
      }

      inner.concat view_context.submit_tag("参与砍价")
      inner.html_safe
    end
    
    html
  end
end
