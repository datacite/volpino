require "rails_helper"
require "cancan/matchers"

describe User, type: :model, vcr: true do
  subject { FactoryGirl.create(:user, github: "mfenner") }

  it { is_expected.to validate_uniqueness_of(:uid) }
  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to have_many(:claims) }

  describe "claims from ORCID" do
    subject { FactoryGirl.create(:user, uid: "0000-0003-1419-2405") }

    it 'get data' do
      result = subject.get_data
      expect(result.length).to eq(26)
      item = result.first
      expect(item["source"]).to eq("source-orcid"=>{"value"=>nil, "uri"=>"http://orcid.org/0000-0001-8099-6984", "path"=>"0000-0001-8099-6984", "host"=>"orcid.org"}, "source-client-id"=>nil, "source-name"=>{"value"=>"DataCite"}, "source-date"=>{"value"=>1439812114541})
    end

    it 'parse data' do
      result = subject.get_data

      result = subject.parse_data(result)
      expect(result.length).to eq(26)
      expect(result).to eq(["10.2314/COSCV2.4", "10.5281/ZENODO.30030", "10.5281/ZENODO.21429", "10.6084/M9.FIGSHARE.1393402", "10.5281/ZENODO.20046", "10.5281/ZENODO.31780", "10.5281/ZENODO.21430", "10.2314/COSCV2", "10.2314/COSCV1.4", "10.6084/M9.FIGSHARE.1041821", "10.2314/COSCV1", "10.6084/M9.FIGSHARE.1048991", "10.6084/M9.FIGSHARE.1066168", "10.6084/M9.FIGSHARE.107019", "10.5281/ZENODO.1239", "10.6084/M9.FIGSHARE.706340", "10.6084/M9.FIGSHARE.824314", "10.6084/M9.FIGSHARE.154691", "10.6084/M9.FIGSHARE.816962", "10.6084/M9.FIGSHARE.816961", "10.6084/M9.FIGSHARE.681735", "10.6084/M9.FIGSHARE.821213", "10.6084/M9.FIGSHARE.821209", "10.3205/12AGMB03", "10.6084/M9.FIGSHARE.90828", "10.6084/M9.FIGSHARE.90829"])
    end
  end

  describe 'push to ORCID' do
    subject { FactoryGirl.create(:user, uid: "0000-0003-1419-2405") }

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
        response = subject.oauth_client_get(endpoint: "orcid-bio/external-identifiers")
        claims = response["data"].fetch("orcid-profile", {})
                                 .fetch("orcid-bio", {})
                                 .fetch("orcid-external-identifiers", {})
                                 .fetch("orcid-external-identifier", [])
        expect(claims.length).to eq(111)
        claim = claims.first
        expect(claim).to eq("put-code"=>"11649252", "work-title"=>{"title"=>{"value"=>"What Can Article-Level Metrics Do for You?"}, "subtitle"=>{"value"=>"PLoS Biology"}, "translated-title"=>nil}, "journal-title"=>nil, "short-description"=>nil, "work-citation"=>{"work-citation-type"=>"BIBTEX", "citation"=>"@article{Fenner_2013, title={What Can Article-Level Metrics Do for You?}, volume={11}, url={http://dx.doi.org/10.1371/journal.pbio.1001687}, DOI={10.1371/journal.pbio.1001687}, number={10}, journal={PLoS Biology}, publisher={Public Library of Science}, author={Fenner, Martin}, year={2013}, month={Oct}, pages={e1001687}}"}, "work-type"=>"JOURNAL_ARTICLE", "publication-date"=>{"year"=>{"value"=>"2013"}, "month"=>nil, "day"=>nil, "media-type"=>nil}, "work-external-identifiers"=>{"work-external-identifier"=>[{"work-external-identifier-type"=>"DOI", "work-external-identifier-id"=>{"value"=>"10.1371/journal.pbio.1001687"}}, {"work-external-identifier-type"=>"ISSN", "work-external-identifier-id"=>{"value"=>"1545-7885"}}], "scope"=>nil}, "url"=>nil, "work-contributors"=>nil, "work-source"=>nil, "source"=>{"source-orcid"=>{"value"=>nil, "uri"=>"http://orcid.org/0000-0002-3054-1567", "path"=>"0000-0002-3054-1567", "host"=>"orcid.org"}, "source-client-id"=>nil, "source-name"=>{"value"=>"CrossRef Metadata Search"}, "source-date"=>{"value"=>1390657436308}}, "created-date"=>{"value"=>1390657436308}, "last-modified-date"=>{"value"=>1437425776076}, "language-code"=>nil, "country"=>nil, "visibility"=>"PUBLIC")
      end
    end

    # describe 'oauth_client_post' do
    #   it 'should post' do
    #     response = subject.oauth_client_post(subject.data, endpoint: "orcid-bio/external-identifiers")
    #     # claim = response["data"].fetch("orcid-profile", {})
    #     #                          .fetch("orcid-bio", {})
    #     #                          .fetch("orcid-external-identifiers", {})
    #     #                          .fetch("orcid-external-identifier", [])
    #     expect(response).to eq("title"=>"omniauth-orcid: v.1.0")
    #   end
    # end

    # describe 'oauth_client_post invalid token' do
    #   subject { FactoryGirl.create(:user, uid: "0000-0003-1419-240x") }

    #   it 'should post' do
    #     response = subject.oauth_client_post(subject.data)
    #     expect(response["errors"].first["title"]).to include("Attempt to retrieve a OrcidOauth2TokenDetail with a null or empty token value")
    #   end
    # end

  #   describe 'push_data' do
  #     it 'no errors' do
  #       response = subject.push_data
  #       claim = response["data"].fetch("orcid-profile", {})
  #                                .fetch("orcid-bio", {})
  #                                .fetch("orcid-external-identifiers", {})
  #                                .fetch("orcid-external-identifier", [])
  #       expect(claim).to eq("title"=>"omniauth-orcid: v.1.0")
  #     end
  #   end

  #   describe 'push_data invalid data' do
  #     it 'it errors' do
  #       allow(subject).to receive(:metadata) { {} }
  #       response = subject.push_data
  #       expect(response["errors"]).to eq([{"title"=>"Missing data"}])
  #     end
  #   end

  #   describe 'push_data invalid token' do
  #     subject { FactoryGirl.create(:user, uid: "0000-0003-1419-240x") }

  #     it 'errors' do
  #       response = subject.push_data
  #       expect(response["errors"].first["title"]).to include("Attempt to retrieve a OrcidOauth2TokenDetail with a null or empty token value")
  #     end
  #   end
  end

  # describe 'schema' do
  #   it 'exists' do
  #     expect(subject.schema.errors).to be_empty
  #   end

  #   it 'validates data' do
  #     expect(subject.validation_errors).to be_empty
  #   end

  #   it 'validates data with errors' do
  #     allow(subject).to receive(:metadata) { {} }
  #     expect(subject.validation_errors).to eq(["The document has no document element."])
  #   end
  # end

  it 'data' do
    xml = File.read(fixture_path + 'external-identifier.xml')
    expect(subject.data).to eq(xml)
  end
end
