require "rails_helper"

describe "/api/v1/services", :type => :api do
  let!(:service) { FactoryGirl.create(:service) }
  let(:headers) { { "HTTP_ACCEPT" => "application/json; version=1" } }
  let(:jsonp_headers) { { "HTTP_ACCEPT" => "application/javascript" } }

  context "index" do
    let(:uri) { "/api/services" }

    it "JSON" do
      get uri, nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      data = response['data']
      expect(data.length).to eq(1)
      item = data.first
      expect(item['id']).to eq('search')
      expect(item['attributes']['title']).to eq('Search')
    end

    it "query" do
      get "#{uri}?query=#{service.name}", nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      data = response['data']
      expect(data.length).to eq(1)
      item = data.first
      expect(item['id']).to eq('search')
      expect(item['attributes']['title']).to eq('Search')
    end
  end

  context "show" do
    let(:uri) { "/api/services/#{service.name}" }

    it "JSON" do
      get uri, nil, headers
      expect(last_response.status).to eq(200)

      response = JSON.parse(last_response.body)
      item = response['data']
      expect(item['id']).to eq('search')
      expect(item['attributes']['title']).to eq('Search')
    end
  end
end
