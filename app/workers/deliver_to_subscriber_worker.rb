class DeliverToSubscriberWorker
  include Sidekiq::Worker

  def self.queue_for_priority(priority)
    if priority == :high
      :high_priority
    elsif priority == :low
      :default
    else
      raise ArgumentError, "priority should be :high or :low"
    end
  end

  sidekiq_options retry: 3, queue: queue_for_priority(:low)

  def perform(email_id)
    email = Email.find(email_id)
    DeliverToSubscriber.call(email: email)
  end

  def self.perform_async_with_priority(*args, priority:)
    set(queue: queue_for_priority(priority))
      .perform_async(*args)
  end
end
