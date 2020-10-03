require 'rails_helper'

describe "users", type: :request, elasticsearch: true do
  let(:params) do
    { "data" => { "type" => "users",
                  "attributes" => {
                    "name" => "Martin Fenner" } } }
  end
  let(:user) { FactoryBot.create(:admin_user, uid: "0000-0002-1825-0097") }
  let(:headers) do
    { "HTTP_ACCEPT" => "application/json; version=1",
      "HTTP_AUTHORIZATION" => "Bearer #{user.jwt}" }
  end
  
  # describe 'GET /users' do
  #   let!(:users)  { create_list(:user, 3) }

  #   before do
  #     User.import
  #     sleep 1
  #   end

  #   it "returns users" do
  #     get "/users", nil, headers

  #     expect(last_response.status).to eq(200)
  #     expect(json['data'].size).to eq(3)
  #     expect(json.dig('meta', 'total')).to eq(3)
  #   end
  # end

  # describe 'GET /users/:id' do
  #   context 'when the record exists', vcr: true do
  #     it 'returns the user' do
  #       get "/users/#{user.uid}", nil, headers

  #       expect(last_response.status).to eq(200)
  #       expect(json.dig("data", "id")).to eq(user.uid)
  #       expect(json.dig("data", "attributes", "name")).to eq(user.name)
  #     end
  #   end
  # end

  describe 'POST /users' do
    context 'request is valid' do
      let(:params) do
        { "data" => { "type" => "users",
                      "attributes" => {
                        "uid" => "0000-0003-2584-9687",
                        "name" => "James Gill",
                        "givenNames" => "James",
                        "familyName" => "Gill" } } }
      end

      it 'creates a user' do
        post '/users', params, headers

        User.import
        sleep 1

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'name')).to eq("James Gill")
      end
    end

    context 'when the request is missing a required attribute' do
      let(:params) do
        { "data" => { "type" => "users",
                      "attributes" => { } } }
      end

      it 'returns a validation failure message' do
        post '/users', params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq("source"=>"uid", "title"=>"Can't be blank")
      end
    end

    context 'when the request is missing a data object' do
      let(:params) do
        { "type" => "users",
          "attributes" => {
            "uid" => "0000-0003-2584-9687",
            "name" => "James Gill"  } }
      end

      it 'returns status code 400' do
        post '/users', params, headers

        expect(last_response.status).to eq(400)
      end

      # it 'returns a validation failure message' do
      #   expect(response["exception"]).to eq("#<JSON::ParserError: You need to provide a payload following the JSONAPI spec>")
      # end
    end
  end

  describe 'PUT /users/:id' do
    context 'when the record exists' do
      let(:params) do
        { "data" => { "type" => "users",
                      "attributes" => {
                        "name" => "James Watt" } } }
      end

      it 'updates the record' do
        put "/users/#{user.uid}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq("James Watt")
      end
    end

    context 'when the record doesn\'t exist', vcr:true do
      let(:new_user) { FactoryBot.build(:user, uid: "0000-0002-0989-1335", name: "Ogechukwu Alozie") }
      let(:params) do
        { "data" => { "type" => "users",
                      "attributes" => {
                        "name" => new_user.name } } }
      end

      it 'updates the record' do
        put "/users/#{new_user.uid}", params, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'name')).to eq(new_user.name)
      end
    end
  end

  # # Test suite for DELETE /users/:id
  # describe 'DELETE /users/:id' do
  #   before { delete "/users/#{user.symbol}", headers: headers }

  #   it 'returns status code 204' do
  #     expect(response).to have_http_status(204)
  #   end
  #   context 'when the resources doesnt exist' do
  #     before { delete '/users/xxx', params: params.to_json, headers: headers }

  #     it 'returns status code 404' do
  #       expect(response).to have_http_status(404)
  #     end

  #     it 'returns a validation failure message' do
  #       expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
  #     end
  #   end
  # end
end
