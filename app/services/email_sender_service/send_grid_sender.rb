require "sendgrid-ruby"

class EmailSenderService
  class SendGridSender #TODO: if we name this consistently with Notify it will clash with the Sendgrid module
    include SendGrid

    def call(address:, subject:, body:)
      #TODO this would have to change as we can't use the notifications email address
      from_address = "test@test.com"

      from = SendGrid::Email.new(email: from_address)
      to = SendGrid::Email.new(email: address)
      content = SendGrid::Content.new(type: 'text/plain', value: body)
      mail = Mail.new(from, subject, to, content)

      client.mail._('send').post(request_body: mail.to_json)
    end

  private

    def client
      @client ||= SendGrid::API.new(api_key: api_key, host: 'https://api.sendgrid.com').client
    end

    def config
      EmailAlertAPI.config.sendgrid
    end

    def metrics_namespace
      "#{Socket.gethostname}.sendgrid.email_send_request"
    end

    def api_key
      config.fetch(:api_key)
    end
  end
end
