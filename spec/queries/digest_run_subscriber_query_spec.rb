RSpec.describe DigestRunSubscriberQuery do
  let(:ends_at) { Time.parse("2017-01-02 08:00") }
  let(:digest_run) { create(:digest_run, :daily, date: ends_at) }
  let(:starts_at) { digest_run.starts_at }

  describe ".call" do
    subject(:subscribers) { described_class.call(digest_run: digest_run) }

    let(:subscriber_list_one) { create(:subscriber_list) }

    def create_and_match_content_change(created_at: starts_at,
      subscriber_list: subscriber_list_one)
      content_change = create(
        :content_change,
        created_at: created_at,
      )
      create(
        :matched_content_change,
        content_change: content_change,
        subscriber_list: subscriber_list,
      )
    end

    context "with one subscription" do
      let!(:subscription) do
        create(:subscription, subscriber_list: subscriber_list_one, frequency: :daily)
      end

      context "with a matched content change" do
        before do
          create_and_match_content_change
        end

        it "returns the subscriber" do
          expect(subscribers.count).to eq(1)
        end
      end

      context "with a matched content change that's out of date" do
        before do
          create_and_match_content_change(created_at: ends_at)
        end

        it "returns no subscribers" do
          expect(subscribers.count).to eq(0)
        end
      end

      context "with no matched content changes" do
        before do
          create(:content_change)
        end

        it "returns no subscribers" do
          expect(subscribers.count).to eq(0)
        end
      end
    end

    context "with an ended subscription" do
      let!(:subscription) do
        create(:subscription, :ended, subscriber_list: subscriber_list_one, frequency: :daily)
      end

      context "with a matched content change" do
        before do
          create_and_match_content_change
        end

        it "returns no subscribers" do
          expect(subscribers.count).to eq(0)
        end
      end
    end

    context "with a weekly subscription" do
      let!(:subscription) do
        create(:subscription, :weekly, subscriber_list: subscriber_list_one)
      end

      context "with a matched content change" do
        before do
          create_and_match_content_change
        end

        it "returns no subscribers" do
          expect(subscribers.count).to eq(0)
        end
      end
    end

    context "with two subscriptions" do
      let!(:subscription_1) do
        create(:subscription, :daily, subscriber_list: subscriber_list_one)
      end

      let!(:subscription_2) do
        create(:subscription, :daily, subscriber_list: subscriber_list_one)
      end

      before do
        create_and_match_content_change
      end

      it "returns the subscribers" do
        expect(subscribers.count).to eq(2)
      end
    end

    context "when the subscriber is subscribed to two matching subscribables" do
      let(:subscriber_list_two) { create(:subscriber_list) }
      let(:subscriber) { create(:subscriber) }
      let!(:subscription_1) do
        create(
          :subscription,
          :daily,
          subscriber: subscriber,
          subscriber_list: subscriber_list_one
        )
      end
      let!(:subscription_2) do
        create(
          :subscription,
          :daily,
          subscriber: subscriber,
          subscriber_list: subscriber_list_two
        )
      end

      before do
        create_and_match_content_change
        create_and_match_content_change(subscriber_list: subscriber_list_two)
      end

      it "only returns the subscriber once" do
        expect(subscribers.count).to eq(1)
      end
    end
  end
end
