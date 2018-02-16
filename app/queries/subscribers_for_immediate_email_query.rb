class SubscribersForImmediateEmailQuery
  def self.call
    Subscriber
      .where(
        SubscriptionContent
          .joins(:subscription)
          .where(email_id: nil)
          .where("subscriptions.subscriber_id = subscribers.id")
          .exists
       )
       .where.not(address: nil)
  end
end
