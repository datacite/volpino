require "rails_helper"
require "cancan/matchers"

describe User, type: :model, vcr: true, elasticsearch: true do
  subject { FactoryBot.create(:valid_user, github: "mfenner", github_put_code: nil) }

  it { is_expected.to validate_uniqueness_of(:uid).case_insensitive }
  it { is_expected.to have_many(:claims) }

  describe "jwt" do
    subject { FactoryBot.create(:regular_user) }

    it 'is user' do
      payload = subject.decode_token(subject.jwt)
      expect(payload["uid"]).to eq(subject.uid)
      expect(payload["role_id"]).to eq("user")
    end

    it 'is admin' do
      subject = FactoryBot.create(:admin_user)
      payload = subject.decode_token(subject.jwt)
      expect(payload["uid"]).to eq(subject.uid)
      expect(payload["role_id"]).to eq("staff_admin")
      expect(payload["features"]).to eq("delete-doi"=>false)
    end
  end

  describe 'push_github_identifier', :order => :defined do
    let(:put_code) { 5583 }
    it 'no errors' do
      expect(subject.github_to_be_created?).to be true
      response = subject.push_github_identifier
      expect(response.body["put_code"]).to eq(put_code)
      expect(response.status).to eq(201)
    end

    it 'delete claim' do
      subject = FactoryBot.create(:valid_user, github: "mfenner", github_put_code: put_code)
      expect(subject.github_to_be_deleted?).to be true
      response = subject.push_github_identifier
      expect(response.body["data"]).to be_blank
      expect(response.body["errors"]).to be_nil
      expect(response.status).to eq(204)
    end
  end

  describe 'process_data', :order => :defined do
    let(:put_code) { 5582 }

    it 'no errors' do
      subject = FactoryBot.create(:valid_user, github: "mfenner", github_put_code: nil)
      expect(subject.process_data).to be true
      expect(subject.github_put_code).to eq(put_code)
    end

    it 'delete claim' do
      subject = FactoryBot.create(:valid_user, github: "mfenner", github_put_code: put_code)
      expect(subject.process_data).to be true
      expect(subject.github_put_code).to be nil
    end
  end

  describe "claims from ORCID" do
    subject { FactoryBot.create(:valid_user) }

    it 'get data' do
      result = subject.get_data
      expect(result.length).to eq(25)
      work = result.first
      path = work.fetch('work-summary', [{}]).first.fetch("source", {}).fetch('source-client-id', {}).fetch('path', nil)
      expect(path).to eq(ENV['ORCID_CLIENT_ID'])
    end

    it 'parse data' do
      result = subject.get_data

      result = subject.parse_data(result)
      expect(result.length).to eq(25)
      expect(result.first).to eq("10.14454/j6gr-cf48")
    end
  end

  describe "claims from notifications" do
    subject { FactoryBot.create(:valid_user) }

    let!(:claim) { FactoryBot.create(:claim, user: subject, orcid: "0000-0001-6528-2027", doi: "10.6084/M9.FIGSHARE.1041821", state: "notified") }

    it 'queue_claims_jobs' do
      subject.queue_claim_jobs
      expect(subject.claims.count).to eq(1)
      updated_claim = subject.claims.first
      expect(updated_claim.state).to eq("notified")
    end
  end
end
