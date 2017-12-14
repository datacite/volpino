require "rails_helper"

describe ExternalIdentifier, type: :model, vcr: true do
  let(:type) { "Github" }
  let(:value) { "mfenner" }
  let(:url) { "https://github.com/#{value}" }
  let(:user) { FactoryBot.create(:valid_user) }
  let(:put_code) { "3879" }

  subject { ExternalIdentifier.new(type: type, value: value, url: url, orcid: user.uid, access_token: user.authentication_token, put_code: put_code) }

  describe 'push to ORCID', :order => :defined do
    describe 'post' do
      subject { ExternalIdentifier.new(type: type, value: value, url: url, orcid: user.uid, access_token: user.authentication_token) }

      it 'should create external_identifier' do
        response = subject.create_external_identifier(sandbox: true)
        expect(response.body["put_code"]).not_to be_blank
      end

      it 'access_token missing' do
        subject = ExternalIdentifier.new(type: type, value: value, url: url, orcid: user.uid, access_token: nil)
        response = subject.create_external_identifier(sandbox: true)
        expect(response.body).to eq("errors"=>[{"title"=>"Access token missing"}])
      end
    end

    describe 'delete' do
      it 'should delete external_identifier' do
        response = subject.delete_external_identifier(sandbox: true)
        expect(response["data"]).to be_blank
        expect(response["errors"]).to be_nil
        expect(response.status).to eq(204)
      end

      it 'access_token missing' do
        subject = ExternalIdentifier.new(type: type, value: value, url: url, orcid: user.uid, access_token: nil)
        response = subject.delete_external_identifier(sandbox: true)
        expect(response.body).to eq("errors"=>[{"title"=>"Access token missing"}])
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
  end

  it 'data' do
    xml = File.read(fixture_path + 'external_identifier.xml')
    expect(subject.data).to eq(xml)
  end
end
