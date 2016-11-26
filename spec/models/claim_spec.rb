require "rails_helper"

describe Claim, type: :model, vcr: true do

  subject { FactoryGirl.create(:claim) }

  it { is_expected.to validate_presence_of(:orcid) }
  it { is_expected.to validate_presence_of(:doi) }
  it { is_expected.to validate_presence_of(:source_id) }
  it { is_expected.to belong_to(:user) }

  describe 'collect_data', :order => :defined do
    let(:user) { FactoryGirl.create(:valid_user) }
    subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.21429") }

    it 'no errors' do
      response = subject.collect_data
      expect(response.body["put_code"]).not_to be_blank
      expect(response.status).to eq(201)
    end

    it 'already exists' do
      FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.21429", claim_action: "create", claimed_at: Time.zone.now, put_code: "741211")
      expect(subject.collect_data).to eq("skip"=>true)
    end

    it 'delete claim' do
      user = FactoryGirl.create(:valid_user)
      subject = FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.21429", claim_action: "delete", claimed_at: Time.zone.now, put_code: "741211")
      response = subject.collect_data
      expect(response.body["data"]).to be_blank
      expect(response.body["errors"]).to be_nil
    end

    it 'no permission for auto-update' do
      user = FactoryGirl.create(:valid_user, auto_update: false)
      subject = FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.21429", source_id: "orcid_update")
      expect(subject.collect_data).to eq("skip"=>true)
    end

    it 'invalid token' do
      user = FactoryGirl.create(:invalid_user)
      subject = FactoryGirl.create(:claim, user: user, orcid: "0000-0003-1419-240x", doi: "10.5281/ZENODO.21429", source_id: "orcid_update")
      response = subject.collect_data
      expect(response.body["notification"]).to be true
      expect(response.body["put_code"]).not_to be_blank
    end

    it 'no user' do
      subject = FactoryGirl.create(:claim, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.21429")
      response = subject.collect_data
      expect(response.body["notification"]).to be true
      expect(response.body["put_code"]).not_to be_blank
    end
  end

  describe 'process_data', :order => :defined do
    let(:user) { FactoryGirl.create(:valid_user) }
    subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.59983") }

    it 'no errors' do
      expect(subject.process_data).to be true
      expect(subject.put_code).not_to be_blank
      expect(subject.claimed_at).not_to be_blank
      expect(subject.human_state_name).to eq("done")
    end

    it 'already exists' do
      FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.59983", claim_action: "create", put_code: "741206")
      expect(subject.process_data).to be true
      expect(subject.human_state_name).to eq("done")
    end

    it 'delete claim' do
      user = FactoryGirl.create(:valid_user)
      subject = FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.59983", claim_action: "delete", put_code: "741206")
      expect(subject.process_data).to be true
      expect(subject.put_code).to be_blank
      expect(subject.claimed_at).to be_blank
      expect(subject.human_state_name).to eq("deleted")
    end

    it 'no permission for auto-update' do
      user = FactoryGirl.create(:valid_user, auto_update: false)
      subject = FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.59983", source_id: "orcid_update")
      expect(subject.process_data).to be true
      expect(subject.human_state_name).to eq("ignored")
    end

    it 'invalid token' do
      user = FactoryGirl.create(:invalid_user)
      subject = FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.59983", source_id: "orcid_update")
      expect(subject.process_data).to be true
      expect(subject.human_state_name).to eq("notified")
    end

    it 'no user' do
      subject = FactoryGirl.create(:claim, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.21429")
      expect(subject.process_data).to be true
      expect(subject.human_state_name).to eq("notified")
    end
  end

  describe 'push to Lagotto' do
    let(:user) { FactoryGirl.create(:valid_user) }
    subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0001-6528-2027", doi: "10.5281/ZENODO.59983") }

    describe 'lagotto_post' do
      it 'should post' do
        response = subject.lagotto_post
        meta = response["data"]['meta']
        deposit = response["data"]['deposit']
        expect(meta).to eq("status"=>"accepted", "message-type"=>"deposit", "message-version"=>"v7")
        expect(deposit['state']).to eq("waiting")
        expect(deposit['message_type']).to eq("contribution")
        expect(deposit['subj_id']).to eq("http://orcid.org/0000-0003-1419-2405")
        expect(deposit['obj_id']).to eq("http://doi.org/10.5281/ZENODO.21429")
        expect(deposit['source_id']).to eq("datacite_search_link")
      end
    end
  end
end
