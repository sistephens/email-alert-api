require "rails_helper"

RSpec.describe "Getting a subscriber list", type: :request do
  include GovDeliveryHelpers

  context "when link match present" do
    before do
      create(:subscriber_list, links: {topics: ["oil-and-gas/licensing", "drug-device-alert"]})
    end

    it "returns the matching subscriber list" do
      get_subscriber_list(links: {topics: ["drug-device-alert", "oil-and-gas/licensing"]})

      response_hash = JSON.parse(response.body)
      subscriber_list = response_hash["subscriber_list"]
      expect(subscriber_list.keys.to_set).to eq(
        %w{
          id
          title
          document_type
          subscription_url
          gov_delivery_id
          created_at
          updated_at
          tags
          links
        }.to_set
      )
      expect(subscriber_list).to include(
        "links" => {
          "topics" => ["oil-and-gas/licensing", "drug-device-alert"]
        }
      )
    end
  end

  context "when tag match present" do
    before do
      create(:subscriber_list, tags: {topics: ["oil-and-gas/licensing", "drug-device-alert"]})
    end

    it "returns a 200" do
      get_subscriber_list(tags: {topics: ["drug-device-alert", "oil-and-gas/licensing"]})

      expect(response.status).to eq(200)
    end

    it "returns the matching subscriber list" do
      get_subscriber_list(tags: {topics: ["drug-device-alert", "oil-and-gas/licensing"]})

      response_hash = JSON.parse(response.body)
      subscriber_list = response_hash["subscriber_list"]
      expect(subscriber_list.keys.to_set).to eq(
        %w{
          id
          title
          subscription_url
          document_type
          gov_delivery_id
          created_at
          updated_at
          tags
          links
        }.to_set
      )
      expect(subscriber_list).to include(
        "tags" => {
          "topics" => ["oil-and-gas/licensing", "drug-device-alert"]
        }
      )
    end
  end

  context "when no match present" do
    it "404s" do
      get_subscriber_list(topics: ["oil-and-gas/licensing"])

      expect(response.status).to eq(404)
    end
  end

  def get_subscriber_list(query_payload)
    get "/subscriber-lists", query_payload, json_headers
  end
end