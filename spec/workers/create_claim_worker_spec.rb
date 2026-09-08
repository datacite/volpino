require "rails_helper"

RSpec.describe(CreateClaimWorker, type: :worker, vcr: true, elasticsearch: true) do
  let!(:user) { FactoryBot.create(:valid_user, uid: "0000-0001-6528-2027") }

  let(:data) do
    { "doi" => "10.14454/1X4X-9056",
      "orcid" => "0000-0001-6528-2027",
      "source_id" => "orcid_update",
      "claim_action" => "create"
    }.to_json
  end

  let(:sqs_msg) do
    double message_id: "6df51f7f-7631-4a90-8df6-216098c29a00", body: data, delete: nil
  end

  subject { CreateClaimWorker.new }

  it "claim is created" do
    subject.perform(sqs_msg, data)

    expect(Claim.where(orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056").exists?).to be true
  end
end
