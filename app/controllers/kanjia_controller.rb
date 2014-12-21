require 'digest/sha1'

class KanjiaController < ApplicationController
  TOKEN = "450013807_kanjia"
  EncodingAESKey = "vcUad8cqlPN9fV7FWX0dRNrZ6svGf34yaGITiz5QGX8"
  
  # signature	微信加密签名，signature结合了开发者填写的token参数和请求中的timestamp参数、nonce参数。
  # timestamp	时间戳
  # nonce	随机数
  # echostr	随机字符串
  #
  def verify    
    str = [TOKEN,params[:timestamp].to_s,params[:nonce].to_s].sort.join('')
    sha1 = Digest::SHA1.hexdigest(str)
    
    Rails.logger.info("str:#{str},sig:#{sha1}")
    if sha1 == params[:signature].to_s
      respond_to do |format|
        format.html {render :text=>parmas[:echostr]}
      end
    else
      respond_to do |format|
        format.html {render :text=>"signature fail"}
      end
    end    
  end
end
