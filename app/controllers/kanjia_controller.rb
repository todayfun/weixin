# encoding:utf-8
require 'digest/sha1'
require 'uri'
require 'net/http'
require 'net/https'

class KanjiaController < ApplicationController
  layout false 
  
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
      Fans.subscribe_by(from)
      
      msg = WeixinHelper.echo_game(to,from,url_for(:action=>:kanjia,:game=>Game.default.guid))
      
      respond_to do |format|
        format.html {render :text=>msg}
      end
    end    
  end
  
  # /kanjia?game=guid for view
  # /kanjia?play=guid for play
  # /kanjia?play=guid for join
  def kanjia
    # get current openid
    openid = ""
    openid = WeixinHelper.query_openid(params[:code]) if params[:state]    
    @share_url = WeixinHelper.share_link(request.full_path)
    
    # get current command
    @cmd = "gameview"    
    @play = nil
    @label = ""
    @links = []
    @title = ""
    if openid.empty?    
      @cmd = "invalid"
      @label = "openid is empty"
    else      
      if params[:play]      
        @play = Play.find_by_guid params[:play]
        if @play
          @cmd = "play"
          owner = @play.owner        
          game = Game.find_by_guid @play.game_guid

          @title = "当前战绩"
          if @play.friends.include?(openid)            
            @label = "您已经砍过了，明天再来"
            if owner==openid
              @links = ["找朋友帮我砍","我的砍价列表"]                         
            end
          else
            if owner==openid
              @label = "自砍一刀"
              @links = ["查看砍价规则","查看砍价排行"]
            else
              @label = "帮TA砍价"
              @links = ["我也要0元拿"]
            end            
          end          
        else
          @cmd = "invalid"
          @label = "cant found play"
        end
      elsif params[:game]
        @cmd = "gameview"
        game = Game.find_by_guid params[:game]      
        if game
          @cmd = "gameview"
          @label = "参与砍价"
          @title = "原始价格"
          @links = ["查看砍价规则","查看砍价排行"]
        else
          @cmd = "invalid"
          @label = "cant found game"
        end
      end
    end
    
    respond_to do |format|
      format.html
    end
  end
      
end
