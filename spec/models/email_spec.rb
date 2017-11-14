require 'rails_helper'

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

    it "requires a content change" do
      subject.valid?
      expect(subject.errors[:content_change]).not_to be_empty
    end
  end

  describe "create_from_params!" do
    let(:content_change) {
      create(:content_change)
    }

    let(:email) {
      Email.create_from_params!(
        title: "Title",
        description: "Description",
        change_note: "Change note",
        base_path: "/government/test",
        public_updated_at: DateTime.parse("1/1/2017"),
        content_change_id: content_change.id,
        address: "test@example.com",
      )
    }

    it "sets subject" do
      expect(email.subject).to eq("Title")
    end

    it "sets body" do
      expect(email.body).to eq(
        <<~BODY
          There has been a change to *Title* on 00:00 1 January 2017.

          > Description

          **Change note**
        BODY
      )
    end
  end
end
