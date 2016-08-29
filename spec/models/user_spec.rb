require "rails_helper"
require "cancan/matchers"

describe User, type: :model, vcr: true do
  subject { FactoryGirl.create(:user, github: "mfenner") }

  it { is_expected.to validate_uniqueness_of(:uid) }
  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to have_many(:claims) }

  describe "claims from ORCID" do
    subject { FactoryGirl.create(:valid_user, uid: "0000-0003-1419-2405") }

    it 'get data' do
      result = subject.get_data
      expect(result.length).to eq(52)
      item = result.first
      expect(item["source"]).to eq("source-orcid"=>{"value"=>nil, "uri"=>"http://orcid.org/0000-0001-8099-6984", "path"=>"0000-0001-8099-6984", "host"=>"orcid.org"}, "source-client-id"=>nil, "source-name"=>{"value"=>"DataCite"}, "source-date"=>{"value"=>1460565737170})
    end

    it 'parse data' do
      result = subject.get_data

      result = subject.parse_data(result)
      expect(result.length).to eq(52)
      expect(result.first).to eq("10.5281/ZENODO.48705")
    end
  end

  describe 'push to ORCID' do
    subject { FactoryGirl.create(:valid_user, uid: "0000-0003-1419-2405") }

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
        claims = response.fetch("data", {})
                         .fetch("orcid-profile", {})
                         .fetch("orcid-bio", {})
                         .fetch("external-identifiers", {})
                         .fetch("external-identifier", [])
        expect(claims.length).to eq(2)
        claim = claims.first
        expect(claim).to eq("orcid"=>nil, "external-id-orcid"=>nil, "external-id-common-name"=>{"value"=>"Scopus Author ID"}, "external-id-reference"=>{"value"=>"7006600825"}, "external-id-url"=>{"value"=>"http://www.scopus.com/inward/authorDetails.url?authorID=7006600825&partnerID=MN8TOARS"}, "external-id-source"=>nil, "source"=>{"source-orcid"=>{"value"=>nil, "uri"=>"http://orcid.org/0000-0002-5982-8983", "path"=>"0000-0002-5982-8983", "host"=>"orcid.org"}, "source-client-id"=>nil, "source-name"=>{"value"=>"Scopus to ORCID"}, "source-date"=>{"value"=>1378921887304}})
      end
    end

    # describe 'oauth_client_post' do
    #   subject { FactoryGirl.create(:valid_user, github: "mfenner") }

    #   it 'should post' do
    #     response = subject.oauth_client_post(subject.data, endpoint: "orcid-bio/external-identifiers")
    #     claims = response.fetch("data", {})
    #                      .fetch("orcid-profile", {})
    #                      .fetch("orcid-bio", {})
    #                      .fetch("external-identifiers", {})
    #                      .fetch("external-identifier", [])
    #     expect(claims.length).to eq(2)
    #     claim = claims.first
    #     expect(claim).to eq("orcid"=>nil, "external-id-orcid"=>nil, "external-id-common-name"=>{"value"=>"ISNI"}, "external-id-reference"=>{"value"=>"000000035060549X"}, "external-id-url"=>{"value"=>"http://isni.org/000000035060549X"}, "external-id-source"=>nil, "source"=>{"source-orcid"=>{"value"=>nil, "uri"=>"http://orcid.org/0000-0003-0412-1857", "path"=>"0000-0003-0412-1857", "host"=>"orcid.org"}, "source-client-id"=>nil, "source-name"=>{"value"=>"ISNI2ORCID search and link"}, "source-date"=>{"value"=>1387382277259}})
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

    # describe 'push_data invalid data' do
    #   it 'it errors' do
    #     subject = FactoryGirl.create(:valid_user, github: nil)
    #     response = subject.push_data
    #     expect(response["errors"]).to eq([{"title"=>"Missing data"}])
    #   end
    # end

    describe 'push_data invalid token' do
      subject { FactoryGirl.create(:valid_user, uid: "0000-0003-1419-240x", github: "mfenner") }

      it 'errors' do
        response = subject.push_data
        expect(response["errors"].first["title"]).to include("Attempt to retrieve a OrcidOauth2TokenDetail with a null or empty token value")
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
      subject = FactoryGirl.create(:valid_user, github: nil)
      expect(subject.validation_errors).to eq(["The document has no document element."])
    end
  end

  it 'data' do
    xml = File.read(fixture_path + 'external-identifier.xml')
    expect(subject.data).to eq(xml)
  end
end
