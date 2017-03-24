class SiteController < ApplicationController
  skip_before_action :check_subscribtion, except: :dashboard

  def index
    @categories = Category.first(3)
  end

  def dashboard
    if current_user
      @top_likes = Like.select('count(*) AS like_count, url, tag_name, created_at').group(:url, :tag_name, :created_at).order('like_count DESC').limit(10)
      query = params[:search] if params[:search]
      @user_tags = current_user.tags.pluck(:tag_name).join(', ')
      max_tags = 5
      @not_added_tags = max_tags - current_user.tags.count

      if !current_user.tags.empty?
        @user_tags_statistic = []
        current_user.tags.each do |tag|
          likes = Like.where(tag_name: tag.tag_name)
          urls =  likes.select(:url).group(:url).pluck(:url)
          urls.each do |u|
            like_count = Like.where(tag_name: tag.tag_name, url: u).count
            like = Like.where(tag_name: tag.tag_name, url: u).order('created_at ASC').first
            countries = Like.select(:country).where(url: u, tag_name: tag.tag_name).pluck(:country).join(', ')
            hash = {'tag_names': tag.tag_name, 'url': u, 'count': like_count, date: like.created_at.strftime("%d %b %Y"), id: like.id, countries: countries }
            @user_tags_statistic.push(hash)
          end
        end
      end

      if query
        search = Like.where(tag_name: query)
        if search.present?
          urls =  search.select(:url).group(:url).pluck(:url)
          @result = Like.get_like_statistic(query, urls, 'urls')
        else
          search = Like.where(url: query)
          tag_names = search.select(:tag_name).group(:tag_name).pluck(:tag_name)
          @result = Like.get_like_statistic(query, tag_names)
        end
      end
    else
      redirect_to user_session_path
    end
  end

  def category
    @category = Category.find_by_name(params[:name])
  end

  def sent_email
    recipient_emails = ['online@gorillatheory.com', 'admin@certifiedpeng.com', 'henrychuks@hotmail.com']
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

  def merchandise
  end


  def contact_us
  end

  def terms
  end

  def about_us
  end

end
