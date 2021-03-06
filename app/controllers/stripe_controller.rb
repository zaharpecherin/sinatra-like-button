class StripeController < ApplicationController
  protect_from_forgery except: :webhooks

  def webhooks
    data_json = JSON.parse request.body.read
    subscriber = Subscriber.find_by_stripe_id(data_json['data']['object']['customer'])
    if data_json['type'] == 'customer.subscription.updated'
      subscriber.end_date = Time.at(data_json['data']['object']['current_period_end']).to_datetime
      subscriber.subscribed = true
    elsif data_json['type'] == 'customer.subscription.deleted'
      subscriber.end_date = nil
      subscriber.subscribed = false
    end
    subscriber.save
    render nothing: true
  end
end