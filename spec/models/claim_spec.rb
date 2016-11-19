require "rails_helper"

describe Claim, type: :model, vcr: true do

  subject { FactoryGirl.create(:claim) }

  it { is_expected.to validate_presence_of(:orcid) }
  it { is_expected.to validate_presence_of(:doi) }
  it { is_expected.to validate_presence_of(:source_id) }
  it { is_expected.to belong_to(:user) }

  describe 'push to ORCID' do
    let(:user) { FactoryGirl.create(:valid_user) }
    subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0003-1419-2405", doi: "10.5281/ZENODO.21429") }

    describe 'collect_data' do
      it 'no errors' do
        response = subject.collect_data
        claim = response["data"].fetch("orcid_message", {})
                        .fetch("orcid_profile", {})
                        .fetch("orcid_activities", {})
                        .fetch("orcid_works", {})
                        .fetch("orcid_work", {})
        expect(claim["work_title"]).to eq("title"=>"omniauth-orcid: v.1.0")
      end
    end

    describe 'collect_data invalid data' do
      it 'it errors' do
        allow(subject).to receive(:metadata) { {} }
        response = subject.collect_data
        expect(response["errors"]).to eq([{"title"=>"Missing data"}])
      end
    end

    describe 'collect_data no permission for auto-update' do
      let(:user) { FactoryGirl.create(:valid_user, auto_update: false) }
      subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0003-1419-2405", doi: "10.5281/ZENODO.21429", source_id: "orcid_update") }

      it 'is empty' do
        expect(subject.collect_data).to be_empty
      end
    end

    describe 'collect_data invalid token' do
      let(:user) { FactoryGirl.create(:user, uid: "0000-0003-1419-240x") }
      subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0003-1419-240x", doi: "10.5281/ZENODO.21429", source_id: "orcid_update") }

      it 'errors' do
        response = subject.collect_data
        expect(response).to eq({})
      end
    end
  end

  describe 'push to Lagotto' do
    let(:user) { FactoryGirl.create(:valid_user) }
    subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0003-1419-2405", doi: "10.5281/ZENODO.21429") }

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
