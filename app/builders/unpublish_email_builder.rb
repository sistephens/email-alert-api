class UnpublishEmailBuilder
  def initialize(email_params)
    @email_params = email_params
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.import!(columns, records)
  end

private
  attr_reader :email_params

  def columns
    %i(address subject body subscriber_id)
  end

  def records
    emails = email_params.map do |param|
      [
        address = param.fetch(:address),
        title = param.fetch(:subject),
        body(title, address),
        param.fetch(:subscriber_id),
      ]
    end
    emails + courtesy_email
  end

  def body(title, address)
    <<~BODY
      Your subscription to ‘#{title}’ no longer exists, as a result you will no longer receive emails
      about this subject.

      #{presented_manage_subscriptions_links(address)}

      &nbsp;

      ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).
    BODY
  end

  def presented_manage_subscriptions_links(address)
    ManageSubscriptionsLinkPresenter.call(address: address)
  end

  def courtesy_email
    addresses = [
      Email::COURTESY_EMAIL,
    ]

    Subscriber.where(address: addresses).map do |subscriber|
      [
        address = subscriber.address,
        title = email_params.first.fetch(:subject),
        body(title, address),
        subscriber.id,
      ]
    end
  end
end
