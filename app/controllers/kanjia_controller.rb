# encoding:utf-8
require 'digest/sha1'
require 'uri'
require 'net/http'
require 'net/https'

class KanjiaController < ApplicationController
  layout false
  
  TOKEN = "450013807_kanjia"
  EncodingAESKey = "vcUad8cqlPN9fV7FWX0dRNrZ6svGf34yaGITiz5QGX8"
  APPID = "wxa3342caaeb251f90"
  SECRET = "1febc2e8f1ce09afdf2dc364c39c2dd9"
  
  def verify    
    str = [TOKEN,params[:timestamp],params[:nonce]].sort.join()
    sha1 = Digest::SHA1.hexdigest(str)
    
    Rails.logger.info("str:#{str},sig:#{sha1}, signature:#{params[:signature]}")
    
    if request.get?
      if sha1 == params[:signature]
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
      content = "kanjia of iphone6 \n <a href='#{url_for :action=>:kanjia}'>wo qu qiang </a>"
      rsp = text_msg(to,from,content)
      #rsp = news_msg(to,from,kanjia_article)
      respond_to do |format|
        format.html {render :text=>rsp}
      end
    end    
  end
  
  def kanjia    
    # friend view
    if params[:state]
      code = params[:code]      

      openid = ""
      if code.nil?
        str = "get openid authorize fail"
      else
        @access_url = %{https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{APPID}&secret=#{SECRET}&code=#{code}&grant_type=authorization_code}
        Rails.logger.info("access_token url:#{@access_url}")
        uri = URI.parse(@access_url)
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        req = Net::HTTP::Get.new(uri.request_uri)        
        rsp = https.request(req)        
        json = ActiveSupport::JSON.decode(rsp.body)
        openid = json["openid"]
        Rails.logger.info("friend openid #{openid}")
        
        # get user info
        url = %{https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{APPID}&secret=#{SECRET}}
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        req = Net::HTTP::Get.new(uri.request_uri)        
        rsp = https.request(req)        
        json = ActiveSupport::JSON.decode(rsp.body)
        Rails.logger.info("token:#{rsp.body}")
        
        access_token = json["json"]
        url = %{https://api.weixin.qq.com/cgi-bin/user/info?access_token=#{access_token}&openid=#{openid}&lang=zh_CN}
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        req = Net::HTTP::Get.new(uri.request_uri)        
        rsp = https.request(req)        
        userjson = ActiveSupport::JSON.decode(rsp.body)
        Rails.logger.info("user info:#{rsp.body}")
      end
    end
    
    scope='snsapi_base'
    back_url=url_for(:action=>:kanjia)            
    @share_url = %{https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{APPID}&redirect_uri=#{CGI.escape(back_url)}&response_type=code&scope=#{scope}&state=1#wechat_redirect}     
    
    respond_to do |format|
      format.html
    end
  end
  
  def kanjia_article
    article = {
      :title=>"kanjia iphone",
      :descritption=>"",
      :picurl=>"http://p0.55tuanimg.com/static/goods/mobile/2014/07/03/13/0153b4cdcf4dba2f9d7b94d6681914d9_3.jpg",
      :url=>url_for(:action=>:kanjia)
    }
    
    [article]
  end
    
  def text_msg(to,from,content)
     rsp = %{<xml>
    <ToUserName><![CDATA[#{to}]]></ToUserName>
    <FromUserName><![CDATA[#{from}]]></FromUserName>
    <CreateTime>#{Time.now.to_i}</CreateTime>
    <MsgType><![CDATA[text]]></MsgType>
    <Content><![CDATA[#{content}]]></Content>
    </xml>}    
    rsp
  end
  
  def news_msg(to,from,articles)    
    items = articles.map do |item|
      %{
    <item>
    <Title><![CDATA[#{item[:title]}]]></Title> 
    <Description><![CDATA[#{item[:description]}]]></Description>
    <PicUrl><![CDATA[#{item[:picurl]}]]></PicUrl>
    <Url><![CDATA[#{item[:url]}]]></Url>
    </item>
     }
    end
    
    %{
    <xml>
    <ToUserName><![CDATA[#{to}]]></ToUserName>
    <FromUserName><![CDATA[#{from}]]></FromUserName>
    <CreateTime>#{Time.now.to_i}</CreateTime>
    <MsgType><![CDATA[news]]></MsgType>
    <ArticleCount>#{articles.size}</ArticleCount>
    <Articles>    
    #{items.join()}
    </Articles>
    </xml> 
    }
  end
end
