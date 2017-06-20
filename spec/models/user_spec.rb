require "rails_helper"
require "cancan/matchers"

describe User, type: :model, vcr: true do
  subject { FactoryGirl.create(:valid_user, github: "mfenner", github_put_code: nil) }

  it { is_expected.to validate_uniqueness_of(:uid) }
  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to have_many(:claims) }

  describe 'push_github_identifier', :order => :defined do
    it 'no errors' do
      expect(subject.github_to_be_created?).to be true
      response = subject.push_github_identifier
      expect(response.body["put_code"]).not_to be_blank
      expect(response.status).to eq(201)
    end

    it 'delete claim' do
      subject = FactoryGirl.create(:valid_user, github: "mfenner", github_put_code: "3826")
      expect(subject.github_to_be_deleted?).to be true
      response = subject.push_github_identifier
      expect(response.body["data"]).to be_blank
      expect(response.body["errors"]).to be_nil
      expect(response.status).to eq(204)
    end
  end

  describe 'process_data', :order => :defined do
    it 'no errors' do
      subject = FactoryGirl.create(:valid_user, github: "mfenner", github_put_code: nil)
      expect(subject.process_data).to be true
      expect(subject.github_put_code).to eq(3827)
    end

    it 'delete claim' do
      subject = FactoryGirl.create(:valid_user, github: "mfenner", github_put_code: "3827")
      expect(subject.process_data).to be true
      expect(subject.github_put_code).to be nil
    end
  end

  describe "claims from ORCID" do
    subject { FactoryGirl.create(:valid_user) }

    it 'get data' do
      result = subject.get_data
      expect(result.length).to eq(26)
      work = result.first
      path = work.fetch('work-summary', [{}]).first.fetch("source", {}).fetch('source-client-id', {}).fetch('path', nil)
      expect(path).to eq(ENV['ORCID_CLIENT_ID'])
    end

    it 'parse data' do
      result = subject.get_data

      result = subject.parse_data(result)
      expect(result.length).to eq(26)
      expect(result.first).to eq("10.5281/ZENODO.49516")
    end
  end

  describe "claims from notifications" do
    subject { FactoryGirl.create(:valid_user) }

    let!(:claim) { FactoryGirl.create(:claim, user: subject, orcid: "0000-0001-6528-2027", doi: "10.6084/M9.FIGSHARE.1041821", state: 6) }

    it 'queue_claims_jobs' do
      subject.queue_claim_jobs
      expect(subject.claims.count).to eq(1)
      updated_claim = subject.claims.first
      expect(updated_claim.human_state_name).to eq("notified")
    end
  end
end
