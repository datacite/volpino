require "rails_helper"

describe Work, type: :model, vcr: true do
  let(:doi) { "10.6084/M9.FIGSHARE.1066168"}
  let(:user) { FactoryGirl.create(:valid_user) }
  let(:put_code) { "740670" }

  subject { Work.new(doi: doi, orcid: user.uid, access_token: user.authentication_token, put_code: put_code) }

  describe 'push to ORCID', :order => :defined do
    describe 'post' do
      subject { Work.new(doi: doi, orcid: user.uid, access_token: user.authentication_token) }

      it 'should create work' do
        response = subject.create_work(sandbox: true)
        expect(response.body["put_code"]).not_to be_blank
      end
    end

    describe 'get' do
      it 'should get works' do
        response = subject.get_works(sandbox: true)
        works = response.body.fetch("data", {}).fetch("group", {})
        expect(works.length).to eq(25)
        work = works.first
        expect(work["external-ids"]).to eq("external-id"=>[{"external-id-type"=>"doi", "external-id-value"=>"10.5167/UZH-19531", "external-id-url"=>nil, "external-id-relationship"=>"SELF"}])
      end
    end

    describe 'put' do
      it 'should update work' do
        response = subject.update_work(sandbox: true)
        expect(response.body.fetch("data", {}).fetch("work", {}).fetch("put_code", nil)).to eq(put_code)
      end
    end

    describe 'delete' do
      it 'should delete work' do
        response = subject.delete_work(sandbox: true)
        expect(response["data"]).to be_blank
        expect(response["errors"]).to be_nil
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
    it 'valid' do
      expect(subject.contributors).to eq([{:credit_name=>"Zohreh Zahedi"}, {:orcid=>"http://orcid.org/0000-0002-2184-6094", :credit_name=>"Martin Fenner"}, {:credit_name=>"Rodrigo Costas"}])
    end

    it 'literal' do
      subject = Work.new(doi: "10.1594/PANGAEA.745083", orcid: "0000-0003-3235-5933", access_token: user.authentication_token, put_code: put_code)
      expect(subject.contributors).to eq([{:credit_name=>"EPOCA Arctic experiment 2009 team"}])
    end

    it 'multiple titles' do
      subject = Work.new(doi: "10.6084/M9.FIGSHARE.1537331.V1", orcid: "0000-0003-0811-2536", access_token: user.authentication_token, put_code: put_code)
      expect(subject.contributors).to eq( [{:credit_name=>"Iosr journals"}, {:credit_name=>"Dr. Rohit Arora, MDS"}, {:credit_name=>"Shalya Raj*.MDS"}])
    end
  end

  it 'publication_date' do
    expect(subject.publication_date).to eq("year" => 2014)
  end

  it 'data' do
    xml = File.read(fixture_path + 'work.xml')
    expect(subject.data).to eq(xml)
  end
end
