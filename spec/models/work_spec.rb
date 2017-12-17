require "rails_helper"

describe Work, type: :model, vcr: true do
  let(:doi) { "10.5438/VQ2T-VR4K"}
  let(:user) { FactoryBot.create(:valid_user) }
  let(:put_code) { "861230" }

  subject { Work.new(doi: doi, orcid: user.uid, access_token: user.authentication_token, put_code: put_code) }

  describe 'push to ORCID', :order => :defined do
    # describe 'post' do
    #   subject { Work.new(doi: doi, orcid: user.uid, access_token: user.authentication_token) }
    #
    #   it 'should create work' do
    #     response = subject.create_work(sandbox: true)
    #     expect(response.body["put_code"]).not_to be_blank
    #   end
    # end

    describe 'get' do
      it 'should get works' do
        response = subject.get_works(sandbox: true)
        works = response.body.fetch("data", {}).fetch("group", {})
        expect(works.length).to eq(25)
        work = works.first
        expect(work["external-ids"]).to eq("external-id"=>[{"external-id-type"=>"doi", "external-id-value"=>"10.5438/53NZ-N4G7", "external-id-url"=>nil, "external-id-relationship"=>"SELF"}])
      end
    end

    # describe 'put' do
    #   it 'should update work' do
    #     response = subject.update_work(sandbox: true)
    #     expect(response.body.dig("data", "work", "put_code")).to eq(put_code)
    #   end
    # end

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

    # it 'validates data' do
    #   expect(subject.validation_errors).to be_empty
    # end

    it 'validates data with errors' do
      allow(subject).to receive(:metadata) { OpenStruct.new }
      expect(subject.validation_errors).to eq(["-1:0: ERROR: The document has no document element."])
    end
  end

  # describe 'contributors' do
  #   it 'valid' do
  #     expect(subject.contributors).to eq([{:orcid=>"http://orcid.org/0000-0003-1419-2405", :credit_name=>"Fenner, Martin"}])
  #   end
  # end
  #
  # it 'publication_date' do
  #   expect(subject.publication_date).to eq("year"=>"2016", "month"=>"07", "day"=>"05")
  # end
  #
  # it 'data' do
  #   xml = File.read(fixture_path + 'work.xml')
  #   expect(subject.data).to eq(xml)
  # end
end
