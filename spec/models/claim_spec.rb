require "rails_helper"

describe Claim, type: :model, vcr: true, elasticsearch: true do
  subject { FactoryBot.create(:claim) }

  it { is_expected.to validate_presence_of(:orcid) }
  it { is_expected.to validate_presence_of(:doi) }
  it { is_expected.to validate_presence_of(:source_id) }
  it { is_expected.to belong_to(:user) }

  describe 'data' do
    let(:user) { FactoryBot.create(:valid_user) }
    subject { FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056") }

    it 'no errors' do
      expect(subject.work.validation_errors).to be_empty
    end
  end

  describe 'collect_data', :order => :defined do
    let(:user) { FactoryBot.create(:valid_user) }
    let(:put_code) { 1069293 }

    subject { FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056") }

    it 'no errors' do
      response = subject.collect_data
      expect(response.body["errors"]).to be_nil
      expect(response.body["put_code"]).to eq(put_code)
      expect(response.status).to eq(201)
    end

    it 'already exists' do
      FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056", claim_action: "create", claimed_at: Time.zone.now)
      expect(subject.collect_data.body).to eq("skip"=>true)
    end

    it 'delete claim' do
      user = FactoryBot.create(:valid_user)
      subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/1X4X-9056", claim_action: "delete", claimed_at: Time.zone.now, put_code: put_code)
      response = subject.collect_data
      expect(response.body["data"]).to be_blank
      expect(response.body["errors"]).to be_nil
    end

    it 'no permission for auto-update' do
      user = FactoryBot.create(:valid_user, auto_update: false)
      subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/v6e2-yc93", source_id: "orcid_update")
      response = subject.collect_data
      expect(response.body).to eq("skip"=>true)
    end

    it 'invalid token' do
      user = FactoryBot.create(:invalid_user)
      subject = FactoryBot.create(:claim, user: user, orcid: "0000-0003-1419-240x", doi: "10.14454/v6e2-yc93", source_id: "orcid_update")
      response = subject.collect_data
      expect(response.body).to eq("skip"=>true)
    end

    it 'no user' do
      subject = FactoryBot.create(:claim, orcid: "0000-0001-6528-2027", doi: "10.14454/v6e2-yc93")
      response = subject.collect_data
      expect(subject.collect_data.body).to eq("skip"=>true)
    end
  end

  describe 'process_data', :order => :defined do
    let(:user) { FactoryBot.create(:valid_user) }
    let(:put_code) { 1069294 }

    subject { FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48") }

    it 'no errors' do
      expect(subject.process_data).to be true
      expect(subject.put_code).to eq(put_code)
      expect(subject.claimed_at).not_to be_blank
      expect(subject.state).to eq("done")
    end
    
    it 'already exists' do
      FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48", claim_action: "create", claimed_at: Time.zone.now, put_code: put_code)
      expect(subject.process_data).to be true
      expect(subject.state).to eq("done")
    end
    
    it 'delete claim' do
      user = FactoryBot.create(:valid_user)
      subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48", claim_action: "delete", put_code: put_code)
      expect(subject.process_data).to be true
      expect(subject.put_code).to be_blank
      expect(subject.claimed_at).to be_blank
      expect(subject.state).to eq("deleted")
    end

    it 'no permission for auto-update' do
      user = FactoryBot.create(:valid_user, auto_update: false)
      subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48", source_id: "orcid_update")
      expect(subject.process_data).to be true
      expect(subject.state).to eq("ignored")
    end

    it 'invalid token' do
      user = FactoryBot.create(:invalid_user)
      subject = FactoryBot.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48", source_id: "orcid_update")
      expect(subject.process_data).to be true
      expect(subject.state).to eq("ignored")
    end

    it 'no user' do
      subject = FactoryBot.build(:claim, user: nil, orcid: "0000-0001-6528-2027", doi: "10.14454/j6gr-cf48")
      expect(subject.process_data).to be true
      expect(subject.state).to eq("ignored")
    end
  end
end
