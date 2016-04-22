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

    describe 'token' do
      it 'should return the user_token' do
        expect(subject.user_token.client.site).to eq("https://api.orcid.org")
      end

      it 'should return the application_token' do
        expect(subject.application_token.client.site).to eq("https://api.orcid.org")
      end
    end

    describe 'oauth_client_get' do
      it 'should get' do
        response = subject.oauth_client_get
        claims = response["data"].fetch("orcid-profile", {})
                                 .fetch("orcid-activities", {})
                                 .fetch("orcid-works", {})
                                 .fetch("orcid-work", [])
        expect(claims.length).to eq(111)
        claim = claims.first
        expect(claim).to eq("put-code"=>"11649252", "work-title"=>{"title"=>{"value"=>"What Can Article-Level Metrics Do for You?"}, "subtitle"=>{"value"=>"PLoS Biology"}, "translated-title"=>nil}, "journal-title"=>nil, "short-description"=>nil, "work-citation"=>{"work-citation-type"=>"BIBTEX", "citation"=>"@article{Fenner_2013, title={What Can Article-Level Metrics Do for You?}, volume={11}, url={http://dx.doi.org/10.1371/journal.pbio.1001687}, DOI={10.1371/journal.pbio.1001687}, number={10}, journal={PLoS Biology}, publisher={Public Library of Science}, author={Fenner, Martin}, year={2013}, month={Oct}, pages={e1001687}}"}, "work-type"=>"JOURNAL_ARTICLE", "publication-date"=>{"year"=>{"value"=>"2013"}, "month"=>nil, "day"=>nil, "media-type"=>nil}, "work-external-identifiers"=>{"work-external-identifier"=>[{"work-external-identifier-type"=>"DOI", "work-external-identifier-id"=>{"value"=>"10.1371/journal.pbio.1001687"}}, {"work-external-identifier-type"=>"ISSN", "work-external-identifier-id"=>{"value"=>"1545-7885"}}], "scope"=>nil}, "url"=>nil, "work-contributors"=>nil, "work-source"=>nil, "source"=>{"source-orcid"=>{"value"=>nil, "uri"=>"http://orcid.org/0000-0002-3054-1567", "path"=>"0000-0002-3054-1567", "host"=>"orcid.org"}, "source-client-id"=>nil, "source-name"=>{"value"=>"CrossRef Metadata Search"}, "source-date"=>{"value"=>1390657436308}}, "created-date"=>{"value"=>1390657436308}, "last-modified-date"=>{"value"=>1437425776076}, "language-code"=>nil, "country"=>nil, "visibility"=>"PUBLIC")
      end
    end

    describe 'oauth_client_post' do
      it 'should post' do
        response = subject.oauth_client_post(subject.data)
        claim = response["data"].fetch("orcid_message", {})
                                .fetch("orcid_profile", {})
                                .fetch("orcid_activities", {})
                                .fetch("orcid_works", {})
                                .fetch("orcid_work", {})
        expect(claim["work_title"]).to eq("title"=>"omniauth-orcid: v.1.0")
      end
    end

    describe 'oauth_client_post invalid token' do
      let(:user) { FactoryGirl.create(:user, uid: "0000-0003-1419-240x") }
      subject { FactoryGirl.create(:claim, user: user, orcid: "0000-0003-1419-240x", doi: "10.5281/ZENODO.21429", source_id: "orcid_update") }

      it 'should post' do
        response = subject.oauth_client_post(subject.data)
        expect(response["errors"].first["title"]).to include("Attempt to retrieve a OrcidOauth2TokenDetail with a null or empty token value")
      end
    end

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
        expect(response["errors"].first["title"]).to include("Attempt to retrieve a OrcidOauth2TokenDetail with a null or empty token value")
      end
    end
  end

  describe 'push to ORCID' do
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

  describe 'schema' do
    it 'exists' do
      expect(subject.schema.errors).to be_empty
    end

    it 'validates data' do
      expect(subject.validation_errors).to be_empty
    end

    it 'validates data with errors' do
      allow(subject).to receive(:metadata) { {} }
      expect(subject.validation_errors).to eq(["The document has no document element."])
    end
  end

  describe 'contributors' do
    let(:user) { FactoryGirl.create(:valid_user) }

    it 'valid' do
      expect(subject.contributors).to eq([{:orcid=>nil, :credit_name=>"Heather A. Piwowar", :role=>nil}, {:orcid=>nil, :credit_name=>"Todd J. Vision", :role=>nil}])
    end

    it 'literal' do
      subject = FactoryGirl.create(:claim, user: user, orcid: "0000-0003-3235-5933", doi: "10.1594/PANGAEA.745083")
      expect(subject.contributors).to eq([{:orcid=>nil, :credit_name=>"EPOCA Arctic experiment 2009 team", :role=>nil}])
    end

    it 'multiple titles' do
      subject = FactoryGirl.create(:claim, user: user, orcid: "0000-0003-0811-2536", doi: "10.6084/M9.FIGSHARE.1537331.V1")
      expect(subject.contributors).to eq([{:orcid=>nil, :credit_name=>"Iosr journals", :role=>nil}, {:orcid=>nil, :credit_name=>"Dr. Rohit Arora, MDS", :role=>nil}, {:orcid=>nil, :credit_name=>"Shalya Raj*.MDS", :role=>nil}])
    end
  end

  it 'publication_date' do
    expect(subject.publication_date).to eq("year" => 2013)
  end

  it 'citation' do
    expect(subject.citation).to eq("@data{http://doi.org/10.5061/DRYAD.781PV, author = {Piwowar, Heather A. and Vision, Todd J.}, title = {Data from: Data reuse and the open data citation advantage}, publisher = {Dryad Digital Repository}, doi = {10.5061/DRYAD.781PV}, url = {http://doi.org/10.5061/DRYAD.781PV}, year = {2013}}")
  end

  it 'data' do
    xml = File.read(fixture_path + 'claim.xml')
    expect(subject.data).to eq(xml)
  end
end
