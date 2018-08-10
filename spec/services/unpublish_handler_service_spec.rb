RSpec.describe UnpublishHandlerService do
  describe ".call" do
    context "email is created and enqueued" do
      before :each do
        subscriber = create(
          :subscriber,
          address: "test@example.com",
          id: 111
        )

        create(
          :subscriber,
          address: Email::COURTESY_EMAIL,
        )

        subscriber_list = create(
          :subscriber_list,
          :taxon_links,
          title: "First Subscription",
        )

        create(
          :subscription,
          id: "bef9b608-05ba-46ce-abb7-8567f4180a25",
          subscriber: subscriber,
          subscriber_list: subscriber_list
        )

        @content_id = subscriber_list.links[:taxon_tree].join
      end

      it "creates an Email" do
        expect { described_class.call(@content_id) }
        .to change { Email.count }.by(2)
      end

      it "increases the size of the queue in the DeliverRequestWorker" do
        pending("switching from logging emails to queuing them ready to be sent")
        Sidekiq::Testing.fake! do
          DeliveryRequestWorker.jobs.clear
          described_class.call(@content_id)
        end
        expect(DeliveryRequestWorker.jobs.size).to eq(2)
      end
    end

    context "email is not created if subscriber is deactivated" do
      before :each do
        deactivated_subscriber = create(
          :subscriber,
          :deactivated,
          address: "test@example.com",
          id: 777
        )

        subscriber_list = create(
          :subscriber_list,
          :taxon_links,
          title: "Subscription",
        )

        create(
          :subscription,
          id: "bef9b608-05ba-46ce-abb7-8567f4180a25",
          subscriber: deactivated_subscriber,
          subscriber_list: subscriber_list
        )

        @content_id = subscriber_list.links.values.flatten.join
      end

      it "doesn't create email if subscriber is deactivated" do
        expect { described_class.call(@content_id) }
        .to_not change { Email.count }
      end
    end

    context "email is not created if there is no SubscriberList" do
      it "doesn't build an email if there is no associated SubscriberList" do
        content_id = "non-existent-content-id"
        expect { described_class.call(content_id) }.to_not(change { Email.count })
      end
    end
  end
end
