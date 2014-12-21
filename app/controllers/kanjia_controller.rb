require 'digest/sha1'

class KanjiaController < ApplicationController
  TOKEN = "450013807_kanjia"
  EncodingAESKey = "vcUad8cqlPN9fV7FWX0dRNrZ6svGf34yaGITiz5QGX8"
  
  def verify    
    str = [TOKEN,params[:timestamp],params[:nonce]].sort.join()
    sha1 = Digest::SHA1.hexdigest(str)
    
    Rails.logger.info("str:#{str},sig:#{sha1}, signature:#{params[:signature]}")
    if sha1 == params[:signature]
      respond_to do |format|
        format.html {render :text=>params[:echostr]}
      end
    else
      respond_to do |format|
        format.html {render :text=>"signature fail"}
      end
    end    
  end

end
