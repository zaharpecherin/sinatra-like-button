class SiteController < ApplicationController
  layout false, only: [:tag_name, :page_like_count, :like]
  protect_from_forgery except: [:tag_name, :page_like_count, :like]
  before_filter :set_access_control_headers, only: [:like, :page_like_count]

  def index
    @categories = Category.all
  end

  def dashboard
    if current_user
      if !current_user.tags.empty?
        @user_tags_statistic = []
        current_user.tags.each do |tag|
          likes = Like.where(tag_name: tag.tag_name)
          urls =  likes.select(:url).group(:url).pluck(:url)
          urls.each do |u|
            like_count = Like.where(tag_name: tag.tag_name, url: u).count
            hash = {'tag_names' => tag.tag_name, 'url' => u, 'count' => like_count }
            @user_tags_statistic.push(hash)
          end
        end
      end

      @top_likes = Like.select('count(*) AS like_count, url, tag_name').group(:url, :tag_name).order('like_count DESC').limit(10)

      query = params[:search] if params[:search]

      if query
        search = Like.where(tag_name: query)
        if search.present?
          urls =  search.select(:url).group(:url).pluck(:url)
          Like.get_like_statistic(query, urls, 'urls')
        else
          search = Like.where(url: query)
          tag_names = search.select(:tag_name).group(:tag_name).pluck(:tag_name)
          Like.get_like_statistic(query, tag_names)
        end
      end
    else
      redirect_to user_session_path
    end
  end

  def category
    @category = Category.find_by_name(params[:name])
  end

  def user_tags
    max_tags = 5
    if params[:tag].present?
      tag = params[:tag]
      if (tag.include? " ") || (tag.include? ",")
        flash[:error] = "Tag must not contain spaces or commas"
      else
        existing_tag = Tag.find_by_tag_name(tag)
        if existing_tag.present?
          flash[:error] = "Tag must be unique"
        else
          if current_user.tags.count == max_tags
            flash[:error] = "You can't add more then 5 tags"
          else
            Tag.create(tag_name: tag, user_id: current_user.id)
          end
        end
      end
      redirect_to user_tags_path
    end
    @not_added_tags = max_tags - current_user.tags.count
    @tags = current_user.tags
  end


  def contact_us
  end

  def terms
  end

  def about_us
  end


  def sent_email
    recipient_emails = ['online@gorillatheory.com', 'henrychuks@hotmail.com']
    if params["g-recaptcha-response"].present?
      name = params[:name]
      email = params[:email]
      telephone = params[:telephone] if params[:telephone]
      reason = params[:reason]
      message = params[:message]
      recipient_emails.each do |recipient|
        NotificationMailer.contact_us_notification(name, email, telephone, reason, message, recipient).deliver
      end

      flash[:notice] = "Thank you for your feedback"
      redirect_to contact_us_path
    else
      flash[:error] = "Do not ignore reCAPTCHA checkbox"
      redirect_to contact_us_path
    end

  end

  def tag_name
    @tag_name = params[:tag_name]
  end

# #create like
  def like

    likes = Like.where(url: params[:url], tag_name: params[:tag_name])
    like_page_by_ip_rel = likes.where(ip: request.ip)

    like_page_by_ip = like_page_by_ip_rel.first
    like_page_by_ip_rel.first_or_create

    ua = request.user_agent
    mobile = 0

    if ['Android', 'iPhone'].find {|s| ua.include?(s) }
      mobile = 1
    end

    render json: { like_count: likes.count, liked: (like_page_by_ip ? 1 : 0), mobile: mobile}

  end


# #get like count
  def page_like_count
    likes = Like.where(url: params[:url], tag_name: params[:tag_name])
    like_page_by_ip = likes.where(ip: request.ip).first

    render json:{ like_count: likes.count, liked: (like_page_by_ip ? 1 : 0) }
  end


  private

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
  end

end
