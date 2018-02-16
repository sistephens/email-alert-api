class ImmediateEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_immediate

  attr_reader :content_changes

  LOCK_NAME = "immediate_email_generation_worker".freeze

  def perform
    @content_changes = {}
    ensure_only_running_once do
      GC.start

      subscribers.find_in_batches do |group|
        subscription_contents_by_subscriber = group_subscription_contents_by_subscriber(group)

        # look up and merge any content changes not already stored

        to_queue = group.flat_map do |subscriber|
          subscription_contents_by_subscriber[subscriber.id].map do |content_changes|
            content_changes.map do |content_change_id, subscription_contents|
              content_change = content_changes[content_change_id]
              subscriptions = subscription_contents.map(&:subscription)

              # do stuff
            end
          end
        end
        # to_queue = []
        # content_change_ids = Set[]
        #
        # group.each do |subscriber|
        #   content_change_ids.merge(subscriber.unprocessed_subscription_contents.map(&:content_change_id))
        # end
        #
        # content_changes = ContentChange.where(id: content_change_ids.to_a)
        #
        # Subscriber.transaction do
        #   email_ids = import_emails(group, content_changes).ids
        #
        #   subscription_contents_to_complete = group_subscription_contents_by_content_change(group)
        #
        #   values = []
        #
        #   email_ids.each_with_index do |email_id, i|
        #     content_change = subscription_contents_to_complete.keys[i]
        #     subscription_contents = subscription_contents_to_complete[content_change]
        #
        #     to_queue << [email_id, content_change.priority.to_sym]
        #
        #     subscription_contents.each do |subscription_content|
        #       values << "(#{subscription_content.id}, #{email_id})"
        #     end
        #   end
        #
        #   ActiveRecord::Base.connection.execute(%(
        #     UPDATE subscription_contents SET email_id = v.email_id
        #     FROM (VALUES #{values.join(',')}) AS v(id, email_id)
        #     WHERE subscription_contents.id = v.id
        #   ))
        # end
        #
        # queue_delivery_request_workers(to_queue)
      end

      GC.start
    end
  end

private

  def group_subscription_contents_by_subscriber(group)
    content = SubscriptionContent
      .includes(:subscription)
      .joins(:subscription)
      .where(email_id: nil, subscriber_id: group.pluck(:id))
      .group(:subscriber_id, :content_change_id)

    # manipulate this somewhat so it's in the form of
    # {
    #   <subscriber_1_id>: {
    #     <content_change_1_id>: [<subscription_content_1>, <subscription_content_2>],
    #     <content_change_2_id>: [<subscription_content_3>]
    #   }
    #   <subscriber_2_id>: {
    #     <content_change_3_id>: [<subscription_content_4>, <subscription_content_5>],
    #   }
    # }
  end

  def ensure_only_running_once
    Subscriber.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      yield
    end
  end

  def queue_delivery_request_workers(queue)
    queue.each do |email_id, priority|
      DeliveryRequestWorker.perform_async_in_queue(
        email_id, queue: queue_for_priority(priority)
      )
    end
  end

  def queue_for_priority(priority)
    if priority == :high
      :delivery_immediate_high
    elsif priority == :normal
      :delivery_immediate
    else
      raise ArgumentError, "priority should be :high or :normal"
    end
  end

  def subscribers
    SubscribersForImmediateEmailQuery.call
  end

  def import_emails(subscribers, content_changes)
    email_params = subscribers.flat_map do |subscriber|
      grouped_subscription_contents = subscriber
        .unprocessed_subscription_contents
        .group_by(&:content_change_id)

      grouped_subscription_contents.map do |content_change_subscription|
        {
          address: subscriber.address,
          content_change: content_changes.find { |cc| cc.id == content_change_subscription[0] },
          subscriptions: content_change_subscription[1].map(&:subscription)
        }
      end
    end

    ImmediateEmailBuilder.call(email_params)
  end

  def group_subscription_contents_by_content_change(subscribers)
    #returns
    #
    # {
    #   content_change => [subscription_content, subscription_content],
    #   content_change => [subscription_content]
    # }
    #
    # which maps to one key per email created
    #
    subscribers.inject({}) do |params, subscriber|
      params.merge!(
        subscriber.unprocessed_subscription_contents.group_by(&:content_change)
      )
    end
  end
end
