# encoding:utf-8
require 'uri'
require 'net/http'
require 'net/https'
require 'digest/sha1'

class WeixinHelper
  TOKEN = "450013807_kanjia"
  EncodingAESKey = "vcUad8cqlPN9fV7FWX0dRNrZ6svGf34yaGITiz5QGX8"
  APPID = "wxa3342caaeb251f90"
  SECRET = "1febc2e8f1ce09afdf2dc364c39c2dd9"
  
  def self.guid
    Digest::SHA1.hexdigest("#{Time.now.to_i},#{rand()}")
  end
  
  def self.is_valid?(sig,timestamp,nonce)
    return false if timestamp.nil?
    
    str = [TOKEN,timestamp,nonce].sort.join()
    sha1 = Digest::SHA1.hexdigest(str)
    
    Rails.logger.info("str:#{str},sig:#{sha1}, signature:#{sig}")
    
    sha1 == sig
  end
  
  # make https request to weixin, get json
  def self.https_get(url)
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Get.new(uri.request_uri)        
    rsp=https.request(req)
    
    ActiveSupport::JSON.decode(rsp.body)
  end
  
  # get userinfo json by openid
  def self.query_userinfo(openid)
    # get user info
    url = %{https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{APPID}&secret=#{SECRET}}
    json = https_get(url)    

    access_token = json["access_token"]
    url = %{https://api.weixin.qq.com/cgi-bin/user/info?access_token=#{access_token}&openid=#{openid}&lang=zh_CN}                     
    json = https_get(url)   
    
    Rails.logger.info("WeixinHelper.query_userinfo: #{json.to_s}")
    json
  end
  
  def self.query_openid(code)
    return nil if code.blank?
    
    url = %{https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{APPID}&secret=#{SECRET}&code=#{code}&grant_type=authorization_code}    
    json = https_get(url)
    
    Rails.logger.info("WeixinHelper.query_openid #{json.to_s}")
    json["openid"]
  end
  
  def self.echo_game(to,from,url)
    content = "kanjia of iphone6 \n <a href='#{url}'>wo qu qiang </a>"
    msg = text_msg(to,from,content)
    
    msg
  end
  
  def self.with_auth(url)     
    url = %{https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{APPID}&redirect_uri=#{CGI.escape(url)}&response_type=code&scope=snsapi_base&state=1#wechat_redirect}
    url
  end
  
  def self.with_auth_userinfo(url)     
    url = %{https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{APPID}&redirect_uri=#{CGI.escape(url)}&response_type=code&scope=snsapi_userinfo&state=1#wechat_redirect}
    url
  end
  
  def self.text_msg(to,from,content)
     rsp = %{<xml>
    <ToUserName><![CDATA[#{to}]]></ToUserName>
    <FromUserName><![CDATA[#{from}]]></FromUserName>
    <CreateTime>#{Time.now.to_i}</CreateTime>
    <MsgType><![CDATA[text]]></MsgType>
    <Content><![CDATA[#{content}]]></Content>
    </xml>}    
    rsp
  end
  
  def self.news_msg(to,from,articles)    
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
