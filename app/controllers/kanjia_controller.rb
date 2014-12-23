# encoding:utf-8
require 'digest/sha1'
require 'uri'
require 'net/http'
require 'net/https'

class KanjiaController < ApplicationController
  layout false
  helper :kanjia
        
  def verify    
    if request.get?
      if WeixinHelper.is_valid?(params[:signature], params[:timestamp],params[:nonce])
        respond_to do |format|
          format.html {render :text=>params[:echostr]}
        end
      else
        respond_to do |format|
          format.html {render :text=>"signature fail"}
        end
      end
    else
      to = params[:xml][:FromUserName]
      from = params[:xml][:ToUserName]            
      Fans.subscribe_by(from) if "subscribe"==params[:xml][:Event]
      
      msg = WeixinHelper.echo_game(to,from,url_for(:action=>:kanjia,:game=>Game.default.guid,:cmd=>"gameview"))
      
      respond_to do |format|
        format.html {render :text=>msg}
      end
    end    
  end
  
  def kanjia
    # get current command    
    @label = ""
    @links = []
    @title = ""
    @share_link = ""
    
    redirect_url = nil
    cmd = params[:cmd]
    case cmd
    # gameview 
    # link:kanjia?game=guid&cmd=gameview
    # click play: weixin_auth(kanjia?game=guid&cmd=gamelaunch)
    # share: kanjia?game=guid&cmd=gameview
    when "gameview"
      game = Game.find_by_guid(params[:game])
      if game        
        @title = "原始价格"
        @label = view_context.link_to("参与砍价",Weixin.with_auth(url_for(:game=>game.guid,:cmd=>"gamelaunch")))
        @share_url = url_for(:game=>game.guid,:cmd=>"gameview")
        @links = [view_context.link_to("查看砍价规则",url_for(:action=>"rule",:game=>game.guid)),view_context.link_to("查看砍价排行",url_for(:action=>"topn",:game=>game.guid))]
      else          
        @label = "#{cmd} fail: cant found game"        
      end
      
    # launchgame
    # link: kanjia?game=guid&cmd=gamelaunch
    # subscribe?：redirect_to weixin_auth(kanjia?play=guid&cmd=playview)
    # unsubscribe?：redirect_to subscribe
    when "launchgame"
      openid = WeixinHelper.query_openid(params[:code])
      
      if openid
        fans = Fans.find_by_openid openid
        if fans
          game = Game.find_by_guid(params[:game])
          if game
            play = Play.where(:game_guid=>game.guid, :owner=>openid).first
            if play.nil?
              play = Play.new
              play.game_guid = game.guid
              play.owner = openid
              play.guid = WeixinHelper.guid
              play.save
            end
            
            @label = "game launched!"
            redirect_url = WeixinHelper.with_auth(url_for(:play=>play.guid,:cmd=>"playview"))            
          else
            @label = "#{cmd} fail: cant found game"
          end
        else
          @label = "#{cmd} fail: 还没订阅公众号"
          redirect_url = url_for(:action=>"subscribe")          
        end
      else
        @label = "#{cmd} fail: cant get openid"
      end
      
    # playview
    # link: weixin_auth(kanjia?play=guid&cmd=playview)
    # doplay: weixin_auth(kanjia?play=guid&cmd=doplay)
    # share: weixin_auth(kanjia?play=guid&cmd=playview)  
    when "playview"
      openid = WeixinHelper.query_openid(params[:code])
      if openid
        play = Play.find_by_guid params[:play]
        if play          
          @title = "当前战绩"
          @share_link = Weixin.with_auth(url_for(:action=>"kanjia",:play=>play.guid,:cmd=>"playview"))
          
          owner = play.owner
          if play.friends.include?(openid)            
            @label = "您已经砍过了，明天再来"
            if owner==openid
              @links = ["找朋友帮我砍",view_context.link_to("我的砍价列表",url_for(:action=>"play_history",:play=>play.guid))]                         
            end
          else
            if owner==openid
              @label = view_context.link_to("自砍一刀",Weixin.with_auth(url_for(:play=>play.guid,:cmd=>"doplay")))
              @links = [view_context.link_to("查看砍价规则",url_for(:action=>"rule",:game=>play.game_guid)),view_context.link_to("查看砍价排行",url_for(:action=>"topn",:game=>play.game_guid))]
            else
              @label = view_context.link_to("帮TA砍价",Weixin.with_auth(url_for(:play=>play.guid,:cmd=>"doplay")))
              @links = [view_context.link_to("我也要0元拿",url_for(:game=>game.guid,:cmd=>"gameview"))]
            end
          end
        else          
          @label = "#{cmd} fail: cant found play"
        end
      else
        @label = "#{cmd} fail: cant get openid"
      end
    
    # playview
    # link: weixin_auth(kanjia?play=guid&cmd=playview)
    # doplay: weixin_auth(kanjia?play=guid&cmd=doplay)
    # share: weixin_auth(kanjia?play=guid&cmd=playview)    
    when "doplay"
      openid = WeixinHelper.query_openid(params[:code])
      if openid
        play = Play.find_by_guid(params[:guid])
        if play
          @label = "do play"
          redirect_url = WeixinHelper.with_auth(url_for(:play=>play.guid,:cmd=>"playview")) 
        else
          @label = "#{cmd} fail: cant found play"
        end
      else
        @label = "#{cmd} fail: cant get openid"
      end
    else
      @label = "invalid cmd"
    end        
    
    if redirect_url
      respond_to do |format|
        format.html {redirect_to redirect_url, :notice=>@label}
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
    respond_to do |format|
      format.html {render :text=>"topN page for #{params[:game]}"}
    end
  end
  
  def subscribe
    respond_to do |format|
      format.html {render :text=>"subscribe page"}
    end
  end
  
  # /play_history?play=guid
  def play_history
    respond_to do |format|
      format.html {render :text=>"play history page for #{params[:play]}"}
    end
  end
end
