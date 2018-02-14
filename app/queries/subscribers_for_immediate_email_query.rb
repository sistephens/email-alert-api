class SubscribersForImmediateEmailQuery
  def self.call
    Subscriber
      .joins(subscriptions: { subscription_contents: :content_change })
      .includes(subscriptions: { unprocessed_subscription_contents: :content_change })
      .where(subscriptions: { subscription_contents: { email_id: nil } })
      .where.not(address: nil)
      .distinct
  end
end
