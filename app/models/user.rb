class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :products

  def admin?
    self.id == 1
  end

  def subscriber?
    user_subscriber = Subscriber.find_by_user_id(self.id)
    if user_subscriber && (user_subscriber.end_date > Time.now)
      user_subscriber.subscribed
    else
      false
    end
  end
end
