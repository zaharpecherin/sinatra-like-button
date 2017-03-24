class PengWidgetController < ApplicationController
  skip_before_action :check_subscribtion
  layout false, only: [:tag_name, :page_like_count, :like]
  protect_from_forgery except: [:tag_name, :page_like_count, :like]
  before_filter :set_access_control_headers, only: [:like, :tag_name, :page_like_count]

  def tag_name
    @tag_name = params[:tag_name]
  end

# #create like
  def like

    if params[:url].last == '/'
      url = params[:url].chop
    end

    likes = Like.where(url: url, tag_name: params[:tag_name])
    like_page_by_ip_rel = likes.where(ip: request.ip)

    like_page_by_ip = like_page_by_ip_rel.first
    like_page = like_page_by_ip_rel.first_or_create

    Like.delay.set_location(like_page)

    ua = request.user_agent
    mobile = 0

    if ['Android', 'iPhone'].find {|s| ua.include?(s) }
      mobile = 1
    end

    render json: { like_count: likes.count, liked: (like_page_by_ip ? 1 : 0), mobile: mobile}

  end


# #get like count
  def page_like_count

    if params[:url].last == '/'
      url = params[:url].chop
    end

    likes = Like.where(url: url, tag_name: params[:tag_name])
    like_page_by_ip = likes.where(ip: request.ip).first

    render json:{ like_count: likes.count, liked: (like_page_by_ip ? 1 : 0) }
  end


  private

  def set_access_control_headers
    headers["Content-Type"] = "text/javascript; charset=utf8"
    headers['Access-Control-Allow-Origin'] = '*'
  end
end
