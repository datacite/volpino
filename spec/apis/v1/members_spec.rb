require "rails_helper"

describe "/api/v1/members", :type => :api do
  let!(:member) { FactoryBot.create(:member, institution_type: "national_organization") }
  let!(:another_member) { FactoryBot.create(:member, name: "TIB", title: "German National Library of Science and Technology", country_code: "DE", institution_type: "academic_institution") }
  let(:headers) { { "HTTP_ACCEPT" => "application/json; version=1" } }
  let(:jsonp_headers) { { "HTTP_ACCEPT" => "application/javascript" } }

  context "index" do
    let(:uri) { "/api/members" }

    it "JSON" do
      get uri, nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      data = response['data']
      expect(data.length).to eq(2)
      item = data.first
      expect(item['id']).to eq('ANDS')
      expect(item['attributes']['title']).to eq('Australian National Data Service (ANDS)')
    end

    it "query" do
      get "#{uri}?query=#{member.name}", nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      data = response['data']
      expect(data.length).to eq(1)
      item = data.first
      expect(item['id']).to eq('ANDS')
      expect(item['attributes']['title']).to eq('Australian National Data Service (ANDS)')
    end

    it "sort by country" do
      get "#{uri}?sort=country", nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      data = response['data']
      expect(data.length).to eq(2)
      item = data.first
      expect(item['id']).to eq('ANDS')
      expect(item['attributes']['title']).to eq('Australian National Data Service (ANDS)')
    end

    it "sort by country desc" do
      get "#{uri}?sort=-country", nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      data = response['data']
      expect(data.length).to eq(2)
      item = data.first
      expect(item['id']).to eq('TIB')
      expect(item['attributes']['title']).to eq('German National Library of Science and Technology')
    end

    it "sort by institution_type" do
      get "#{uri}?sort=institution-type", nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      data = response['data']
      expect(data.length).to eq(2)
      item = data.first
      expect(item['id']).to eq('TIB')
      expect(item['attributes']['title']).to eq('German National Library of Science and Technology')
    end

    it "sort by institution_type desc" do
      get "#{uri}?sort=-institution-type", nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      data = response['data']
      expect(data.length).to eq(2)
      item = data.first
      expect(item['id']).to eq('ANDS')
      expect(item['attributes']['title']).to eq('Australian National Data Service (ANDS)')
    end
  end

  context "show" do
    let(:uri) { "/api/members/#{member.name}" }

    it "JSON" do
      get uri, nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      item = response['data']
      expect(item['id']).to eq('ANDS')
      expect(item['attributes']['title']).to eq('Australian National Data Service (ANDS)')
    end
  end
end
