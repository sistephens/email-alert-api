class UnpublishHandlerService
  UNPUBLISH_LOG_PATH = "#{Rails.root}/log/unpublish_message.log".freeze

  def initialize(content_id)
    @content_id = content_id
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    if email_params(subscriber_lists).empty?
      nil
    elsif includes_taxon_unpublishing?
      email_ids = UnpublishEmailBuilder.call(email_params(subscriber_lists)).ids
      log_taxon_emails(email_ids)
    else
      log_non_taxon_lists(subscriber_lists)
    end
  end

private
  attr_reader :content_id

  def includes_taxon_unpublishing?
    subscriber_lists.first.links.keys.include?(:taxon_tree)
  end

  def queue_delivery_request_workers(email_ids)
    email_ids.each do |email_id|
      DeliveryRequestWorker.perform_async_in_queue(
        email_id, queue: :delivery_immediate
      )
    end
  end

  def email_params(subscriber_lists)
    @email_params ||= subscriber_lists.flat_map do |subscriber_list|
      subscriber_list.subscribers.activated.map do |subscriber|
        {
          subject: subscriber_list.title,
          address: subscriber.address,
          subscriber_id: subscriber.id
        }
      end
    end
  end

  # For this query to return the content id has to be wrapped in a double quote blame psql 9.3
  def subscriber_lists
    @subscriber_lists ||= SubscriberList
      .where(":id IN (SELECT json_array_elements((json_each(links)).value)::text)", id: "\"#{content_id}\"")
      .includes(:subscribers)
      .to_a
  end

  def log_taxon_emails(email_ids)
    Email.where(id: email_ids).each do |email|
      logger.info(<<-INFO.strip_heredoc)
        ----
        Created Email:
        id: #{email.id}
        subject: #{email.subject}
        body: #{email.body}
        subscriber_id: #{email.subscriber_id}
        ----
      INFO
    end
  end

  def log_non_taxon_lists(subscriber_lists)
    subscriber_lists.each do |list|
      logger.info(<<-INFO.strip_heredoc)
        ++++
        Not sending notification about non-Topic SubscriberList.
        id: #{list.id}
        title: #{list.title}
        links: #{list.links}
        tags: #{list.tags}
        ++++
      INFO
    end
  end

  def logger
    @logger ||= Logger.new(UNPUBLISH_LOG_PATH, 5, 4194304)
  end
end
