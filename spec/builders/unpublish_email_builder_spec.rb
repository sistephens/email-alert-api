RSpec.describe UnpublishEmailBuilder do
  describe ".call" do
    let(:subscriber) {
      create(
        :subscriber,
        address: "address@test.com",
        id: 999
      )
    }

    let!(:courtesy_subscriber) {
      create(
        :subscriber,
        address: Email::COURTESY_EMAIL
      )
    }

    let(:params) {
      [
        {
          address: "address@test.com",
          subject: "subject_test",
          subscriber_id: subscriber.id,
        }
      ]
    }

    subject(:email_import) { described_class.call(params) }

    let(:email) { Email.find(email_import.ids.first) }

    it "returns an email import" do
      expect(email_import.ids.count).to eq(2)
    end

    it "sets the subject" do
      expect(email.subject).to eq("subject_test")
    end

    it "sets the subscriber id" do
      expect(email.subscriber_id).to eq(999)
    end

    it "sets the body and checks status" do
      expect(email.status).to eq "pending"

      expect(email.body).to eq(
        <<~BODY
          Your subscription to ‘subject_test’ no longer exists, as a result you will no longer receive emails
          about this subject.

          [View and manage your subscriptions](http://www.dev.gov.uk/email/authenticate?address=address%40test.com)

          &nbsp;

          ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).
        BODY
      )
    end
  end
end
