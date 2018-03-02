class SubscriptionsController < ApplicationController
  def create
    return render json: { id: 0 }, status: :created if smoke_test_address?

    existing_subscription = nil
    subscription = nil

    Subscription.transaction do
      existing_subscription = Subscription.active.lock.find_by(
        subscriber: subscriber,
        subscriber_list: subscribable,
      )

      existing_subscription.end(reason: :frequency_changed) if existing_subscription

      subscriber.activate! if subscriber.deactivated?

      subscription = Subscription.create!(
        subscriber: subscriber,
        subscriber_list: subscribable,
        frequency: frequency,
        signon_user_uid: current_user.uid,
        source: existing_subscription ? :frequency_changed : :user_signed_up
      )
    end

    status = existing_subscription ? :ok : :created
    render json: { id: subscription.id }, status: status
  end

private

  def smoke_test_address?
    address.end_with?("@notifications.service.gov.uk")
  end

  def subscriber
    @subscriber ||= begin
                      found = Subscriber.find_by(address: address)
                      found || Subscriber.create!(
                        address: address,
                        signon_user_uid: current_user.uid,
                      )
                    end
  end

  def address
    subscription_params.require(:address)
  end

  def subscribable
    @subscribable ||= SubscriberList.find(subscription_params.require(:subscribable_id))
  end

  def frequency
    subscription_params.fetch(:frequency, "immediately").to_sym
  end

  def subscription_params
    params.permit(:address, :subscribable_id, :frequency)
  end
end
