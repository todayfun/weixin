#encoding:utf-8
module KanjiaHelper
  def launch_game_url(label,uri,openid)
    link_to(label,uri.to_s).html_safe
  end
  
  def play_game_url(label,uri,openid)
    link_to(label,uri.to_s).html_safe
  end
end
