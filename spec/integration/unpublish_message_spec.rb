RSpec.describe "Sending an unpublish message", type: :request do
  context "with authentication and authorisation" do
    before :each do
      subscriber = create(
        :subscriber,
        address: "test@example.com",
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

      @request_params = { content_id: subscriber_list.links.values.flatten.join }.to_json
    end

    before do
      login_with_internal_app
      post "/unpublish-messages", params: @request_params, headers: JSON_HEADERS
    end

    it "creates a Email" do
      expect(Email.count).to eq(2)
    end
  end
end
