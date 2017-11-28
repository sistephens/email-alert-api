require "sendgrid-ruby"

class EmailSenderService
  class SendGridSender #TODO: if we name this consistently with Notify it will clash with the Sendgrid module
    include SendGrid

    class SendGridBodyConverter
      def self.to_text(markdown)
        <<~TEXT
          text version

          #{markdown}

        TEXT
      end

      def self.to_html(markdown)
        <<~HTML
          <h1>HTML Version</h1>

          <p> Parse me *************************</p>

          #{markdown}

          <p> **********************************</p>
        HTML
      end
    end

    def call(address:, subject:, body:)
      #TODO we can't use the notifications email address
      from_address = "test@test.com"
      to = SendGrid::Email.new(email: address)
      plain_text = SendGrid::Content.new(type: 'text/plain', value: SendGridBodyConverter.to_text(body))
      from = SendGrid::Email.new(email: from_address)

      mail = Mail.new(from, subject, to, plain_text)
      mail.add_content(SendGrid::Content.new(type: 'text/html', value: SendGridBodyConverter.to_html(body)))

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
