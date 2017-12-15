class NotifyProvider
  attr_accessor :client, :template_id

  def self.call(*args)
    new.call(*args)
  end

  def initialize(config: EmailAlertAPI.config.notify)
    api_key = config.fetch(:api_key)
    base_url = config.fetch(:base_url)

    self.client = Notifications::Client.new(api_key, base_url)
    self.template_id = config.fetch(:template_id)
  end

  def call(address:, subject:, body:, reference:)
    client.send_email(
      email_address: address,
      template_id: template_id,
      reference: reference,
      personalisation: {
        subject: subject,
        body: body,
      },
    )

    MetricsService.sent_to_notify_successfully
  rescue Notifications::Client::RequestError
    MetricsService.failed_to_send_to_notify
    raise ProviderError
  end
end