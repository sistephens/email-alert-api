require "rails_helper"

RSpec.describe SubscriberList, type: :model do
  describe ".build_from(params:, gov_delivery_id:)" do
    let(:params) {
      {
        title: "Ronnie Pickering",
        tags: { topics: ["motoring/road_rage"] },
        links: { topics: ["uuid-888"] },
      }
    }
    let(:gov_delivery_id) { "GOVUK_888" }

    let(:list) {
      SubscriberList.build_from(params: params, gov_delivery_id: gov_delivery_id)
    }

    it "builds a new SubscriberList without a format" do
      expect(list.title).to eq "Ronnie Pickering"
      expect(list.tags).to eq({:topics=>["motoring/road_rage"]})
      expect(list.links).to eq({:topics=>["uuid-888"]})
      expect(list.gov_delivery_id).to eq "GOVUK_888"
      expect(list.document_type).to be_nil
    end

    it "builds a new SubscriberList with a format" do
      params[:document_type] = "travel_advice"
      expect(list.document_type).to eq "travel_advice"
    end
  end

  describe "#tags" do
    it "deserializes the tag arrays" do
      list = create(:subscriber_list, tags: { topics: ["environmental-management/boating"] })
      list.reload

      expect(list.tags).to eq(topics: ["environmental-management/boating"])
    end
  end

  describe "#subscription_url" do
    it "provides the subscription URL based on the gov_delivery_id" do
      list = SubscriberList.new(gov_delivery_id: "UKGOVUK_4567")

      expect(list.subscription_url).to eq(
        "http://govdelivery-public.example.com/accounts/UKGOVUK/subscriber/new?topic_id=UKGOVUK_4567"
      )
    end
  end
end