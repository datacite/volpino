# frozen_string_literal: true

require "rails_helper"

describe Claim, type: :model, vcr: true, elasticsearch: true do
  subject { FactoryBot.create(:claim) }

  it { is_expected.to validate_presence_of(:orcid) }
  it { is_expected.to validate_presence_of(:doi) }
  it { is_expected.to validate_presence_of(:source_id) }
  it { is_expected.to belong_to(:user) }

  # describe 'data' do
  #   let(:user) { FactoryBot.create(:valid_user) }
  #   subject { FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056") }

  #   it 'no errors' do
  #     expect(subject.work.validation_errors).to be_empty
  #   end
  # end

  describe "claim uses correct token" do
    let(:user) { FactoryBot.create(:valid_user) }

    it "uses the auto update token" do
      user = FactoryBot.create(:valid_user, auto_update: false)
      subject = FactoryBot.create(:claim, user: user, source_id: "orcid_update")
      expect(subject.orcid_token).to eq(user.orcid_token)
    end

    it "uses the search and link token" do
      user = FactoryBot.create(:valid_user, auto_update: false)
      subject = FactoryBot.create(:claim, user: user, source_id: "orcid_search")
      expect(subject.orcid_token).to eq(user.orcid_search_and_link_access_token)
    end
  end

  sources = [ "orcid_search", "orcid_update" ]
  sources.each do |source|
    describe "collect_data with source #{source}", order: :defined do
      let(:user) { FactoryBot.create(:valid_user) }
      let(:put_code) { 1069293 }

      subject { FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056") }

      # it 'no errors' do
      #   response = subject.collect_data
      #   expect(response.body["errors"]).to eq([{"title"=>"Missing data"}])
      #   expect(response.body["put_code"]).to be_nil
      #   expect(response.status).to eq(201)
      # end

      # TODO
      # it "already exists" do
      #   FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056", claim_action: "create", put_code: put_code)
      #   expect(subject.collect_data.body).to eq("reason" => "already claimed.", "skip" => true)
      # end

      # it 'delete claim' do
      #   user = FactoryBot.create(:valid_user)
      #   subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056", claim_action: "delete", claimed_at: Time.zone.now, put_code: put_code)
      #   response = subject.collect_data
      #   expect(response.body["data"]).to be_blank
      #   expect(response.body["errors"]).to eq([{"title"=>"Missing data"}])
      # end

      ## This test is no longer necessary as the auto_update flag has been replaced by presence of auto_update token
      # it "no permission for auto-update" do
      #   user = FactoryBot.create(:valid_user, auto_update: false)
      #   subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/v6e2-yc93", source_id: "orcid_update")
      #   response = subject.collect_data
      #   expect(response.body).to eq({ "errors" => [{ "title" => "No auto-update permission" }] })
      # end

      it "missing token" do
        user = FactoryBot.create(:invalid_user)
        subject = FactoryBot.create(:claim, user: user, orcid: "0000-0003-1419-240x", doi: "10.14454/v6e2-yc93", source_id: source)
        response = subject.collect_data
        expect(response.body).to eq({ "errors" => [{ "title" => "No user and/or ORCID token" }] })
      end

      it "expired token" do
        user = FactoryBot.create(:valid_user, orcid_expires_at: Time.zone.now - 7.days, orcid_search_and_link_expires_at: Time.zone.now - 7.days)
        subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056", source_id: source)
        response = subject.collect_data
        expect(response.body).to eq("errors" => [{ "status" => 401, "title" => "token has expired." }])
      end

      # TODO
      # it "invalid token" do
      #   user = FactoryBot.create(:invalid_user, orcid_token: "123")
      #   subject = FactoryBot.create(:claim, user: user, orcid: "0000-0003-1419-240x", doi: "10.14454/v6e2-yc93", source_id: "orcid_update")
      #   response = subject.collect_data
      #   expect(response.body).to eq("errors"=>[{"title"=>"Missing data"}])
      # end

      it "no user" do
        subject = FactoryBot.create(:claim, orcid: "0000-0001-6528-2027", doi: "10.14454/v6e2-yc93")
        response = subject.collect_data
        expect(response.body).to eq("errors" => [{ "title" => "No user and/or ORCID token" }])
      end
    end

    describe "process_data with source #{source}", order: :defined do
      let(:user) { FactoryBot.create(:valid_user) }
      let(:put_code) { 1069294 }

      subject { FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48") }

      # it 'no errors' do
      #   expect(subject.process_data).to be true
      #   expect(subject.put_code).to be_blank
      #   expect(subject.claimed_at).to be_blank
      #   expect(subject.state).to eq("failed")
      # end

      # TODO
      # it "already exists" do
      #   FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48", claim_action: "create", put_code: put_code)
      #   expect(subject.process_data).to be true
      #   expect(subject.state).to eq("done")
      # end

      # it 'delete claim' do
      #   user = FactoryBot.create(:valid_user)
      #   subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48", claim_action: "delete", put_code: put_code)
      #   expect(subject.process_data).to be true
      #   expect(subject.put_code).to eq(1069294)
      #   expect(subject.claimed_at).to be_blank
      #   expect(subject.state).to eq("failed")
      # end

      it "no permission for auto-update" do
        user = FactoryBot.create(:valid_user, auto_update: false)
        subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48", source_id: source)
        expect(subject.process_data).to be true
        expect(subject.state).to eq("failed") # This used to be 'ignored' but the code is correctly returning an error struct and thus setting it to failed
      end

      it "invalid token" do
        user = FactoryBot.create(:invalid_user)
        subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48", source_id: source)
        expect(subject.process_data).to be true
        expect(subject.state).to eq("failed") # This used to be 'ignored' but the code is correctly returning an error struct and thus setting it to failed
      end

      it "no user" do
        subject = FactoryBot.build(:claim, user: nil, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48")
        expect(subject.valid?).to be false
        expect(subject.errors[:user]).to include("must exist")
      end
    end
  end
end
