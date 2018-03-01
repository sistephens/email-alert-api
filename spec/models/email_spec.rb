RSpec.describe Email do
  describe "validations" do
    it "requires subject" do
      subject.valid?
      expect(subject.errors[:subject]).not_to be_empty
    end

    it "requires body" do
      subject.valid?
      expect(subject.errors[:body]).not_to be_empty
    end
  end

  describe "#finish_sending" do
    context "when delivery attempt is for same email" do
      let(:email) { create(:email) }
      let(:delivery_attempt) { create(:delivery_attempt, email: email) }

      it "sets the finished_sending_at field" do
        Timecop.freeze do
          expect { email.finish_sending(delivery_attempt) }
            .to change { email.finished_sending_at }
            .from(nil)
            .to(Time.now)
        end
      end
    end

    context "when delivery_attempt is for a different email" do
      let(:email) { create(:email) }
      let(:delivery_attempt) { build(:delivery_attempt) }

      it "raises an error" do
        expect { email.finish_sending(delivery_attempt) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
