#encoding:utf-8
class CaidanController < ApplicationController
  layout "caidan"  
  @@subscribe_url = "http://mp.weixin.qq.com/s?biz=MzA3OTg5MzMxNg==&mid=204493713&idx=1&sn=0b03c8ebbb9303882d0208c992a48c95#rd"

  def wxdata
    wxdata = {
    :title=>"幸福彩蛋大家砸，砸碎大奖拿回家，蛋蛋有奖，门槛低，拿奖易！",
    :img_url=>url_for(:controller=>"zadan.jpg"),
    :link=>url_for(:action=>"gameview"),
    :desc=>"红蛋、黄蛋、蓝蛋、彩蛋，五彩缤纷的幸福彩蛋等你来砸，蛋蛋有奖，蛋砸碎了蛋里的宝贝就是你的啦！快召集你的蛋友来帮忙砸蛋吧！"
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
    @game = Game.caidan
    @wxdata = wxdata
    @wxdata[:link] = url_for(:action=>"gameview")
    
    @banner = nil
    @btn_links = []
    @tair_links = []
    redirect_url = nil            
    openid = _get_openid()    
    if openid.nil?
      redirect_url = WeixinHelper.with_auth_userinfo(request.url)
      @banner = "cant get openid"
    else
      if params[:from_weixin] == "zhongqi"
        cookies[:from_weixin] = @game.guid        
      end

      unless _has_subscribed?
        @banner = "gameview fail: 还没订阅公众号"
        redirect_url = @@subscribe_url
      else          
        play = Play.where(:game_guid=>@game.guid,:owner=>openid).first
        if play
          @banner = "已经创建了游戏，直接进入"
          redirect_url = url_for(:play=>play.guid,:action=>"playview")
        else
          @banner = _select_eggs
          
          @tair_links << view_context.link_to(%{<div class="kan-section tight">砸蛋规则</div>}.html_safe,url_for(:action=>"rule"))            
          @tair_links << view_context.link_to(%{<div class="kan-section tight">奖品展示</div>}.html_safe,url_for(:action=>"jiangpin"))
          @tair_links << view_context.link_to(%{<div class="kan-section tight">砸蛋排行</div>}.html_safe,url_for(:action=>"topn"))
        end
      end
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
  
  def gamelaunch
    @game = Game.caidan
    
    openid = _get_openid()
    if openid.nil?
      redirect_url = WeixinHelper.with_auth_userinfo(request.url)
      @banner = "cant get openid"
    else
      egg_name = params[:caidan]||"egg_red"
      args = @game.args
      if args[egg_name]
        play = Play.launchgame(openid, @game) do |p|
          egg = args[egg_name]
          # state: egg_name,done_cnt, todo_cnt
          args = {egg_name=>egg,"selected"=>egg_name,"state"=>[egg[0],0,egg[1]]}          
          p.args = args
          p.score = egg[1]
        end

        flash[:notice] = _doplay(play,openid)
        cookies[:notice]=true
        @banner = "game launched!"
        redirect_url = url_for(:play=>play.guid,:action=>"playview")
      else
        flash[:notice] = "egg #{egg_name} not exists"
        redirect_url = url_for(:action=>"gameview")
      end
    end
        
    respond_to do |format|
      format.html {redirect_to redirect_url}
    end    
  end
  
=begin
我的砸蛋记录
=end  
  def playview
    @play = Play.find_by_guid(params[:play])
    redirect_url = nil
    if @play.nil?
      redirect_url = url_for(:action=>"gameview")
    else
    
    @game = Game.caidan
    @wxdata = wxdata
    @wxdata[:link] = url_for(:play=>@play.guid,:action=>"playview")
    
    @banner = nil
    @btn_links = []
    @tair_links = []
    openid = _get_openid()    
    if openid.nil?
      redirect_url = WeixinHelper.with_auth_userinfo(request.url)
      @banner = "cant get openid"
    else
      if @play
        if openid == @play.owner
          if _has_played?(@play,openid)            
            @banner = _show_egg(@play,%{<div class="btn btn-lg btn-danger">您已经砸过啦</div>})
            
            #@btn_links = %{找朋友帮我砸 我的砸蛋记录}
            link = view_context.link_to(%{<div class="btn btn-sm btn-danger">找朋友帮我砸</div>}.html_safe,"javascript:void()",:onclick=>"showShare();")            
            link.concat view_context.link_to(%{<div class="btn btn-sm btn-danger">我的砸蛋记录</div>}.html_safe, url_for(:action=>"playhistory",:play=>@play.guid))            
            @btn_links << link
          else            
            @banner = _show_egg(@play,view_context.link_to(%{<div class="btn btn-lg btn-danger">自己砸一下</div>}.html_safe,url_for(:play=>@play.guid,:action=>"doplay")))
          end                
        else          
          if _has_played?(@play,openid)
            @banner =  _show_egg(@play,%{<div class="btn btn-lg btn-danger">您已经帮TA砸过啦</div>})
            
            @btn_links << view_context.link_to(%{<div class="btn btn-lg btn-danger">我也要砸彩蛋</div>}.html_safe,url_for(:action=>"gameview"))
            @btn_links << view_context.link_to(%{<div class="btn btn-lg btn-danger">找朋友帮TA砍</div>}.html_safe,"#",:onclick=>"showShare();")
          else
            @banner = _show_egg(@play,view_context.link_to(%{<div class="btn btn-lg btn-danger">帮TA砸一下</div>}.html_safe,url_for(:play=>@play.guid,:action=>"doplay")))
            @btn_links << view_context.link_to(%{<div class="btn btn-lg btn-danger">我也要砸彩蛋</div>}.html_safe,url_for(:action=>"gameview"))                     
          end
        end
        
        # @tair_links = %{活动规则 奖品展示 幸福的人}
        @tair_links << view_context.link_to(%{<div class="kan-section tight">砸蛋规则</div>}.html_safe,url_for(:action=>"rule"))            
        @tair_links << view_context.link_to(%{<div class="kan-section tight">奖品展示</div>}.html_safe,url_for(:action=>"jiangpin"))
        @tair_links << view_context.link_to(%{<div class="kan-section tight">砸蛋排行</div>}.html_safe,url_for(:action=>"topn"))
      else
        @banner = "playview fail: cant found play"
        redirect_url = url_for(:action=>"gameview")
      end
    end
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
  
=begin
1、一个ID在活动期间，帮不同人砸蛋的次数，累计不能超过5次。
2、一次活动中，比如，A发起的砸蛋活动，只能帮A砸一次。
3、同一个ID，只能发起一次活动，只能自己砸一次。
4、如果超过了砸蛋次数，则弹出窗口提示：“对不起，你的5次砸蛋权已经用完啦，换个手机和微信再来参加吧！”
=end  
  def doplay
    @play = Play.find_by_guid(params[:play])
    @game = Game.caidan
    
    openid = _get_openid()
    redirect_url = nil
    if openid.nil?
      redirect_url = WeixinHelper.with_auth_userinfo(request.url)
      @banner = "cant get openid"
    else
      if @play
        if _has_subscribed?          
          flash[:notice] = _doplay(@play,openid)
          cookies[:notice]=true          
          redirect_url = url_for(:play=>@play.guid,:action=>"playview")
        else
          @label = "doplay fail: 还没订阅公众号"
          cookies[:doplay_url] = request.url
          redirect_url = @@subscribe_url
        end
      else
        @banner = "doplay fail: cant found play"
        redirect_url = url_for(:action=>"gameview")
      end
    end
    
    respond_to do |format|
      format.html {redirect_to redirect_url}
    end
  end
    
  def dozadan
    @game = Game.caidan
    redirect_url = url_for(:action=>"gameview", :game=>@game.guid)
    if params[:from_weixin] == "zhongqi"
      cookies[:from_weixin] = @game.guid
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
    @game = Game.caidan    
    @game_url = request.referer || url_for(:action=>"gameview")
    @wxdata = wxdata()
    @wxdata[:link] = url_for(:action=>"gameview")
    
    state = @play.args["state"]
    @label = %{已砸#{state[1]}次，还差#{state[2]}次就碎啦，加油！}
    
    @nicknames = {}
    Fans.where(:openid=>@play.friends).each do |f|
      @nicknames[f.openid] = f.nickname
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  def rule
    @game = Game.caidan    
    @game_url = request.referer || url_for(:action=>"gameview")
    @wxdata = wxdata()
    @wxdata[:link] = url_for(:action=>"gameview")
    
    respond_to do |format|
      format.html
    end
  end
    
  def topn
    @game = Game.caidan    
    @game_url = request.referer || url_for(:action=>"gameview")
    @wxdata = wxdata()
    @wxdata[:link] = url_for(:action=>"gameview")
    t = Time.now.utc
    @cnt = Play.where("game_guid='#{@game.guid}' and start_at < '#{t}'").order("score asc").count
    
    plays = Play.where("game_guid='#{@game.guid}' and start_at < '#{t}'").joins("join fans on fans.openid=plays.owner").select("plays.*,fans.nickname").order("score asc").limit(50)
    @topn = plays.map do |p|      
      state = p.args["state"] # egg_name,done_cnt, todo_cnt
      name = p.nickname
      next if name.length < 4
      name[1]="."
      name[2]="."      
      [name, state[0],state[1], state[2]]
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  def jiangpin
    @game = Game.caidan    
    @game_url = request.referer || url_for(:action=>"gameview")
    @wxdata = wxdata()
    @wxdata[:link] = url_for(:action=>"gameview")
    
    respond_to do |format|
      format.html
    end
  end
  
  def _has_subscribed?
    if !cookies[:from_weixin].blank?
      true
    else
      false
    end    
  end
  
  def _select_eggs
    game = Game.caidan
    eggs = game.args
    
    eggs_html = ""
    eggs.keys.sort.each do |egg_name|
      egg = eggs[egg_name]
      eggs_html.concat %{
        <li>
            <label onclick="document.getElementById('jiangpin').innerHTML = '需砸：#{egg[1]}次&nbsp;&nbsp;&nbsp;&nbsp;奖品：#{egg[2]}';">
              <img class="inlineblock" src="/#{egg_name}.png" alt="">
              <input class="inlineblock" type="radio" value="#{egg_name}" name="caidan">
            </label>
        </li>
      }
    end
    
    html = view_context.form_tag "/caidan/gamelaunch" do
      inner = %{
      <ul class="caidan">
      #{eggs_html}
      </ul>
      <div class="red center" id="jiangpin"></div>
      <div class="kan-section" style="z-index:-1">请谨慎选择蛋的颜色，你只有一次发起砸蛋活动的权利哦，看看你能召集多少蛋友来帮你砸蛋，再合理选择蛋的颜色哦！</div>
      <div class="kan-section"><button type="submit" class="btn btn-lg btn-danger">抡起锤子砸一下</button></div>
      }
      
      inner.html_safe
    end
    
    html
  end
  
  def _show_egg(play,label)
    args = play.args
    state = args["state"]
    egg_name = args["selected"]
    
    # egg: ["红蛋",50,"Paul Frank钱包"]
    %{
    <div class="kan-section center">
        <img class="inlineblock" src="/#{egg_name}.png" alt="">
    </div>
    <div class="center red">已砸#{state[1]}次，还需砸#{state[2]}次就碎啦，加油！</div>
    <br/>
    #{label}
    }
  end
  
  def _get_openid
    #return "boyii2"
    openid = cookies[:weixin_openid]    
    if openid.nil? && params[:code]
      userinfo = WeixinHelper.query_userinfo_by_auth(params[:code])
      Fans.save_by_userinfo userinfo
      openid = userinfo['openid']
      
      cookies[:weixin_openid] = { :value => openid, :expires => 30.minutes.from_now }
      Rails.logger.info("Get openid from weixin")
    end
    
    openid
  end
  
  def _has_played?(play,openid)   
    friends = play.friends    
    key = "#{openid}"
    friends.include?(key)
    #false
  end
  
=begin
1、一个ID在活动期间，帮不同人砸蛋的次数，累计不能超过3次。
2、一次活动中，比如，A发起的砸蛋活动，只能帮A砸一次。
3、同一个ID，只能发起一次活动，只能自己砸一次。
4、如果超过了砸蛋次数，则弹出窗口提示：“对不起，你的3次砸蛋权已经用完啦，换个手机和微信再来参加吧！”
=end
  def _doplay(play,openid)
    notice = {:type=>"good",:msg=>""}
    
    if _has_played?(play,openid)
      if openid == play.owner
        notice[:msg] = "您已经帮TA砸过一次啦，不能再砸啦！邀请其他小伙伴来帮忙砸吧。您也可以参加“幸福彩蛋大家砸，砸碎大奖拿回家”活动，蛋蛋有奖！"
      else
        notice[:msg] = "您已经砸过一次啦，不能再砸啦！邀请其他小伙伴来帮忙砸吧。蛋砸碎了蛋里的宝贝就是你的啦！"
      end
      
      notice[:type] = "warning"
    elsif play.status == "CLOSED"
      notice[:msg] = "本次活动已经结束啦，看看其他活动!"
      notice[:type] = "warning"
    else
      args = play.args
      friends = play.friends
      friend_plays = play.friend_plays
      
      # egg: ["红蛋",50,"Paul Frank钱包"]
      if friends.empty?
        egg = args[args["selected"]]
        play.score = egg[1]
      end
      
      play.score -= 1
      todo_cnt = play.score.to_i      
      args["state"] = [egg[0],(egg[1]-todo_cnt),todo_cnt] # egg_name,done_cnt, todo_cnt
      friends << openid
      friend_plays << [openid,todo_cnt,Time.now]
      play.status = "CLOSED" if todo_cnt == 0
      play.friends = friends
      play.friend_plays = friend_plays
      play.args = args
      play.save!
      
      if todo_cnt == 0        
        if openid == play.owner        
          notice[:msg] = %{恭喜您，已经砸开了#{egg[0]}，快去领取大奖吧！}
          notice[:type] = "good"
        else
          notice[:msg] = %{太厉害了，您帮TA砸开了#{egg[0]}，快叫TA去领取大奖吧。您也可以参加“幸福彩蛋大家砸，砸碎大奖拿回家”活动，蛋蛋有奖！}
          notice[:type] = "good"
        end
      else
        if openid == play.owner        
          notice[:msg] = %{呜呜，好硬的蛋，一下子砸不碎，还需砸#{todo_cnt}下才能砸碎哦，快邀请你的蛋友来帮你砸蛋吧，蛋砸碎了蛋里的宝贝就是你的啦！}
          notice[:type] = "good"
        else
          notice[:msg] = %{感谢恩人赏了一锤，离免费大奖又近了一步，快去留个言邀功吧。您也可以参加“幸福彩蛋大家砸，砸碎大奖拿回家”活动，蛋蛋有奖！}
          notice[:type] = "good"
        end
      end                  
    end
    
    notice
  end    
end
