require "rails_helper"
require "cancan/matchers"

describe User, type: :model, vcr: true do
  subject { FactoryGirl.create(:user) }

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
end
