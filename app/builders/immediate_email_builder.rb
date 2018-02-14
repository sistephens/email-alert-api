class ImmediateEmailBuilder
  def initialize(params)
    @params = params
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :params

  def records
    params.map do |param|
      [
        param.fetch(:address),
        subject(param.fetch(:content_change)),
        body(param.fetch(:content_change), param.fetch(:subscriptions))
      ]
    end
  end

  def columns
    %i(address subject body)
  end

  def subject(content_change)
    "GOV.UK Update - #{content_change.title}"
  end

  def body(content_change, subscriptions)
    if Array(subscriptions).empty?
      presented_content_change(content_change)
    else
      <<~BODY
        #{presented_content_change(content_change)}
        ---

        #{presented_unsubscribe_links(subscriptions)}
      BODY
    end
  end

  def presented_content_change(content_change)
    ContentChangePresenter.call(content_change)
  end

  def presented_unsubscribe_links(subscriptions)
    links_array = subscriptions.map do |subscription|
      UnsubscribeLinkPresenter.call(
        uuid: subscription.uuid,
        title: subscription.subscriber_list.title,
      )
    end

    links_array.join("\n")
  end
end
