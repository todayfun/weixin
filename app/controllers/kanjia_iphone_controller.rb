# encoding:utf-8
class KanjiaIphoneController < ApplicationController
  layout "kanjia"
  @@subscribe_url = "http://mp.weixin.qq.com/s?__biz=MzA5MDkyMzcxMg==&mid=201988152&idx=1&sn=0c2a17684759fa47b028b369093e2f4c#rd"

  def wxdata
    wxdata = {
    :title=>"一刀砍掉800元，砍到0元iPhone6就是你的啦，快召集朋友来帮你砍吧。",
    :img_url=>url_for(:controller=>"iphone.jpg"),
    :link=>url_for(:action=>"gameview",:game=>Game.kanjia_iphone.guid),
    :desc=>"免费召唤iPhone6，先自砍一刀，再邀请小伙伴们来帮你砍价，砍到0元，宝贝就是你的啦！比比谁的朋友多，呼朋唤友，齐心合力，免费大奖拿回家！还等什么？"
    }
    
    wxdata
  end  
  
  def reset
    cookies[:openid_iphone] = nil    
    cookies[:from_weixin] = nil
    cookies[:friend_iphone] = nil    
    
    respond_to do |format|
      format.html {redirect_to @@subscribe_url}
    end
  end
  
  def gameview
    # get current command    
    @label = ""
    @btn_links = []
    @tair_links = []
    @title = ""    
    @notice = nil
    @wxdata = wxdata()
       
    @game = Game.find_by_guid(params[:game]) || Game.kanjia_iphone    
    
    redirect_url = nil
    cmd = params[:cmd]||"gameview"    

    # gameview 
    # link:kanjia?game=guid&cmd=gameview
    # click play: weixin_auth(kanjia?game=guid&cmd=gamelaunch)
    # share: kanjia?game=guid&cmd=gameview    
    openid = get_openid()
    game = @game
    if game                
      if params[:from_weixin] == "zhongqi"
        cookies[:from_weixin] = game.guid        
      end

      unless has_subscribed?
        @label = "#{cmd} fail: 还没订阅公众号"
        redirect_url = @@subscribe_url
      else          
        play = Play.where(:game_guid=>game.guid,:owner=>openid).first
        if play && openid
          @title = "已经创建了游戏，直接进入"
          redirect_url = url_for(:play=>play.guid,:cmd=>"playview",:action=>"kanjia")
        else
          if openid
            #@label = view_context.link_to("参与砍价",url_for(:game=>game.guid,:cmd=>"gamelaunch"))
            @label = view_context.link_to(%{<div class="btn btn-lg btn-danger">参与砍价!</div>}.html_safe,
              url_for(:game=>game.guid,:cmd=>"gamelaunch"))
          else
            @label = input_nickname(game.guid)
          end
          @title = %{
          <div class="btn btn-danger btn-lg active">
          快来参与： <del class="kan-old">￥#{game.args["origin_price"]/100.0}</del> <strong class="kan-new">￥#{game.args["origin_price"]/100.0}</strong>
          </div>
          }          
          @wxdata[:link] = url_for(:game=>game.guid,:action=>"gameview")
          #@btn_links = [view_context.link_to("查看砍价规则",url_for(:action=>"rule",:game=>game.guid)),view_context.link_to("查看砍价排行",url_for(:action=>"topn",:game=>game.guid))]
          @tair_links << view_context.link_to(%{<div class="kan-section tight">查看砍价规则</div>}.html_safe,url_for(:action=>"rule",:game=>game.guid))            
          @tair_links << view_context.link_to(%{<div class="kan-section tight">查看砍价排行</div>}.html_safe,url_for(:action=>"topn",:game=>game.guid))
        end
      end
    else
      @label = "#{cmd} fail: cant found game"
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
  
  def kanjia
    # get current command    
    @label = ""
    @btn_links = []
    @tair_links = []
    @title = ""    
    @notice = nil
    @wxdata = wxdata()
       
    @game = nil
    @play = Play.find_by_guid(params[:play])
    @game = Game.find_by_guid(@play.game_guid) if @play
    @game ||= Game.find_by_guid(params[:game]) || Game.kanjia_iphone    
    
    redirect_url = nil
    cmd = params[:cmd]||"gameview"    

    # gameview 
    if "gameview"==cmd
      redirect_url = url_for(:action=>"gameview",:game=>params[:game],:from_weixin=>params[:from_weixin])

    # launchgame
    # link: kanjia?game=guid&cmd=gamelaunch
    # subscribe?：redirect_to weixin_auth(kanjia?play=guid&cmd=playview)
    # unsubscribe?：redirect_to subscribe
    elsif "gamelaunch"==cmd
      openid = get_openid()
      unless openid
        openid = set_openid(params[:playowner])
      end
      
      if openid
        #if has_subscribed?
          game = Game.find_by_guid(params[:game])
          if game
            play = Play.launchgame(openid,game)

            @label = "game launched!"
            redirect_url = url_for(:play=>play.guid,:cmd=>"playview")
          else
            @label = "#{cmd} fail: cant found game"
          end
        #else                 
        #end
      else
        @label = "请输入正确的微信昵称"
        flash[:notice] = {:msg=>"请输入正确的微信昵称",:type=>"warning"}
        cookies[:notice]=true
        redirect_url = url_for(:game=>params[:game],:action=>"gameview")
      end

    # playview
    # link: weixin_auth(kanjia?play=guid&cmd=playview)
    # doplay: weixin_auth(kanjia?play=guid&cmd=doplay)
    # share: weixin_auth(kanjia?play=guid&cmd=playview)  
    elsif "playview"==cmd
      openid = get_openid()
      play = Play.find_by_guid params[:play]
      if play        
        @title = %{
        <div class="btn btn-danger btn-lg active">
        砍价战绩： <del class="kan-old">￥#{play.args["origin_price"]/100.0}</del> <strong class="kan-new">￥#{play.args["current_price"]/100.0}</strong>
        </div>
        }
        
        @wxdata[:link] = url_for(:play=>play.guid,:cmd=>"playview")
        
        if openid == play.owner
          if has_played?(play,openid)
            #@label = "您已经砍过了!"
            @label = %{<div class="btn btn-lg btn-danger">您已经砍过了!</div>}
            
            #@btn_links = ["找朋友帮我砍",view_context.link_to("我的砍价列表",url_for(:action=>"play_history",:play=>play.guid))]
            link = view_context.link_to(%{<div class="btn btn-sm btn-danger">找朋友帮我砍</div>}.html_safe,"#",:onclick=>"showShare();")            
            link.concat view_context.link_to(%{<div class="btn btn-sm btn-danger">我的砍价列表</div>}.html_safe,
              url_for(:action=>"play_history",:play=>play.guid))            
            @btn_links << link
          else
            #@label = view_context.link_to("挥刀自砍",url_for(:play=>play.guid,:cmd=>"doplay"))
            @label = view_context.link_to(%{<div class="btn btn-lg btn-danger">挥刀自砍</div>}.html_safe,
              url_for(:play=>play.guid,:cmd=>"doplay"))
          end          
                
        else
          friend = get_friend()
          if has_played?(play,friend)
            @label = %{<div class="btn btn-lg btn-danger">您已经帮TA砍过价了!</div>}
            @btn_links << view_context.link_to(%{<div class="btn btn-lg btn-danger">我也要0元拿</div>}.html_safe,url_for(:game=>play.game_guid,:action=>"gameview"))
            @btn_links << view_context.link_to(%{<div class="btn btn-lg btn-danger">找朋友帮TA砍</div>}.html_safe,"#",:onclick=>"showShare();")
          else
            @label = view_context.link_to(%{<div class="btn btn-lg btn-danger">帮TA砍价</div>}.html_safe,
              url_for(:play=>play.guid,:cmd=>"doplay"))   
                        
            @btn_links << view_context.link_to(%{<div class="btn btn-lg btn-danger">我也要0元拿</div>}.html_safe,url_for(:game=>play.game_guid,:action=>"gameview"))                     
          end
        end        
        
        @tair_links << view_context.link_to(%{<div class="kan-section tight">查看砍价规则</div>}.html_safe,url_for(:action=>"rule",:game=>play.game_guid))
        @tair_links << view_context.link_to(%{<div class="kan-section tight">查看砍价排行</div>}.html_safe,url_for(:action=>"topn",:game=>play.game_guid))    
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
        if has_subscribed?
          @label = "do play"        
          flash[:notice] = doplay(play,openid)
          cookies[:notice]=true          
          redirect_url = url_for(:play=>play.guid,:cmd=>"playview")
        else
          @label = "#{cmd} fail: 还没订阅公众号"
          cookies[:doplay_url_iphone] = request.url
          redirect_url = @@subscribe_url
        end
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
  
  def dokanjia    
    game = Game.kanjia_iphone
    redirect_url = url_for(:action=>"gameview", :game=>game.guid)
    if params[:from_weixin] == "zhongqi"
      cookies[:from_weixin] = game.guid
    end
    
    if !cookies[:doplay_url_iphone].blank?
      redirect_url = cookies[:doplay_url_iphone]      
    end
    
    respond_to do |format|
      format.html {redirect_to redirect_url}
    end
  end
  
  # link: rule?game=guid
  def rule
    @game = Game.find_by_guid params[:game] || Game.kanjia_iphone
    @game_url = request.referer || url_for(:action=>"gameview",:game=>@game.guid)
    @wxdata = wxdata()
    @wxdata[:link] = @game_url
    
    respond_to do |format|
      format.html
    end
  end
  
  # link: topn?game=guid
  def topn
    Play.seed_kanjia_winners_iphone
    
    t = Time.now.utc
    plays = Play.where("game_guid='#{params[:game]}' and start_at < '#{t}'").order("score desc").limit(50)
    @cnt = Play.where("game_guid='#{params[:game]}' and start_at < '#{t}'").order("score desc").count
    @cnt += Play.seed_count_iphone
        
    @game = Game.find_by_guid params[:game] || Game.kanjia_iphone
    @game_url = request.referer || url_for(:action=>"gameview",:game=>@game.guid)
    @wxdata = wxdata()
    @wxdata[:link] = @game_url
    
    if !plays.empty?
      @topn = plays.map do |play|        
        name = play.owner.strip
        next if name.blank?
        
        f = name[0]
        if f.match(/\d/)
          i=f.to_i
          f = ('a'..'z').to_a[i]
          f = f.upcase if [1,3,5].include?(i)
        end
        
        name = f + name[1].to_s + "..." + name[-1]
        [name, play.start_at.to_date.to_s,play.args["discount"]/100.0,play.args["current_price"]/100.0]
        #"#{play.owner},#{play.args["origin_price"]},#{play.args["current_price"]},#{play.args["discount"]}"
      end    
    end
        
    respond_to do |format|
      format.html
    end
  end
  
  # /play_history?play=guid
  def play_history
    @play = Play.find_by_guid params[:play]
    @game = Game.find_by_guid(@play.game_guid) if @play
    @game ||= Game.find_by_guid params[:game] || Game.kanjia_iphone
    @game_url = url_for(:action=>"gameview",:game=>@game.guid)
    @wxdata = wxdata()
    @wxdata[:link] = @game_url
    
    @title = %{
    <div class="btn btn-danger">
    砍价战绩： <del class="kan-old">￥#{@play.args["origin_price"]/100.0}</del> <strong class="kan-new">￥#{@play.args["current_price"]/100.0}</strong>
    </div>
    }
    respond_to do |format|
      format.html
    end
  end
  
  def get_openid    
    cookies[:openid_iphone]
    cookies[:openid_iphone].blank? ? nil : cookies[:openid_iphone].strip
  end
  
  def set_openid(openid)
    cookies[:openid_iphone] = openid.blank?  ? nil : openid
  end
    
  def get_friend
    friend = cookies[:friend_iphone]
    if friend.blank?
      friend = WeixinHelper.guid
      cookies[:friend_iphone] = friend
    end
  
    friend
  end
  
  def has_subscribed?
    if !cookies[:from_weixin].blank?
      true    
    end    
  end
  
=begin
1	1	1000	1600
2-11	10	110	120
12-21	10	95	100
22-31	10	75	80
32-41	10	55	60
42-51	10	48	50
52-66	15	38	40
67-71	15	28	30
72-91	20	18	20
92-121	30	9	10
122-161	40	1	5
162-261	100	0	0.2
262-361	100	0	0.1
362-1061 700	0	0.01
价格低于7687时，系统提示，对不起，由于您存在作弊行为，取消您此次活动的资格。
=end  
  def doplay(play,openid)
    notice = {:type=>"good",:msg=>""}
    
    if has_played?(play,openid)
      notice[:msg] = "今天您已经砍过一次啦，明天再来吧！或者邀请其他小伙伴来帮忙砍吧。心动不如行动，你也快来参加iPhone6疯狂砍活动，砍到0元，宝贝就是你的啦！"      
      notice[:type] = "warning"
    elsif play.status == "CLOSED"
      notice[:msg] = "HI，本次活动已经结束啦，看看其他活动!"
      notice[:type] = "warning"
    else
      friends = play.friends
      friend_plays = play.friend_plays
      args = play.args
      args["current_price"] ||= args["origin_price"]      
      cnt = friends.size+1

      # 以分为单位，变成整数运算
      discount = case cnt
      when 1
        20000+rand(60000) # 1	1	200	800
      when 2..11
        11000+rand(1000) # 2-11	10	110	120
      when 12..21
        9500+rand(500) # 12-21	10	95	100
      when 22..31
        7500+rand(500) # 22-31	10	75	80
      when 32..41
        5500+rand(500) # 32-41	10	55	60
      when 42..51
        4800+rand(200) # 42-51	10	48	50
      when 52..66
        3800+rand(200) # 52-66	15	38	40
      when 67..71
        2800+rand(200) # 67-71	15	28	30
      when 72..91
        1800+rand(200) # 72-91	20	18	20
      when 92..121
        900+rand(100) # 92-121	30	9	10
      when 122..161
        100+rand(400) # 122-161	40	1	5
      when 162..261
        rand(20) # 162-261	100	0	0.2
      when 262..361
        rand(10) # 262-361	100	0	0.1
      when 362..1061
        rand(1) # 362-1061 700	0	0.01
      else
        0
      end

      now = Time.now
      key = "#{openid},#{now.to_date.to_s}"
      if args["current_price"] > discount
        args["current_price"] -= discount
      else
        discount = args["current_price"]
        args["current_price"] = 0
        play.status = "CLOSED"
        play.end_at = now
      end

      args["discount"] = args["origin_price"] - args["current_price"]    
      friend_plays << [openid,discount,args["current_price"],now]
      friends << key

      play.score = args["origin_price"] - args["current_price"]
      play.args = args
      play.friends = friends
      play.friend_plays = friend_plays
      play.save

      cnt = Play.where("score>#{play.score} and stamp='#{play.stamp}'").count
      if play.owner==openid
        notice[:msg] = %{真厉害！大拿你为自己砍了#{discount/100.0}元！在好友中排名第#{cnt+1}位，快邀请朋友帮你砍价，砍到0元，iPhone6就是你的啦！}
        notice[:type] = "good"
      else
        notice[:msg] = %{真厉害，帮TA一下子砍了#{discount/100.0}元，大奖越来越近了哦！}
        notice[:type] = "good"
      end
    end    
    
    notice
  end
  
  def has_played?(play,openid)   
    friends = play.friends    
    key = "#{openid},#{Date.today.to_s}"
    friends.include?(key)
    #false
  end
  
  def input_nickname(game_guid)
    html = view_context.form_tag "/kanjia_iphone/kanjia?game=#{game_guid}&cmd=gamelaunch" do
      inner = %{
      <input type="text" name= "playowner" placeholder="输入微信号，一起来砍价"/>
      <input class="btn btn-lg btn-danger" type="submit" value="参与砍价"/> 
      }
      
      inner.html_safe
    end
    
    html
  end
end
