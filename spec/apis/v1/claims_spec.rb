require "rails_helper"

describe "/api/v1/claims", :type => :api do
  before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8)) }

  let(:claim) { FactoryGirl.build(:claim) }
  let(:error) { { "errors" => [{"status"=>"401", "title"=>"You are not authorized to access this page."}] } }
  let(:success) { { "id"=>claim.uuid,
                    "type"=>"claims",
                    "attributes"=>{ "orcid"=>claim.orcid,
                                    "doi"=>claim.doi,
                                    "source_id"=>claim.source_id,
                                    "state"=>"waiting",
                                    "claimed_at"=>nil} }}
  let(:user) { FactoryGirl.create(:admin_user) }
  let(:uuid) { SecureRandom.uuid }
  let(:headers) do
    { "HTTP_ACCEPT" => "application/json; version=1",
      "HTTP_AUTHORIZATION" => "Token token=#{user.authentication_token}" }
  end

  context "create" do
    let(:uri) { "/api/claims" }
    let(:params) do
      { "claim" => { "uuid" => claim.uuid,
                     "orcid" => claim.orcid,
                     "doi" => claim.doi,
                     "source_id" => claim.source_id } }
    end

    context "as admin user" do
      it "JSON" do
        post uri, params, headers
        #expect(last_response.status).to eq(202)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response["data"]).to eq(success)
      end
    end

    context "as staff user" do
      let(:user) { FactoryGirl.create(:user, role: "staff") }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "as regular user" do
      let(:user) { FactoryGirl.create(:user, role: "user") }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "without orcid" do
      let(:params) do
        { "claim" => { "uuid" => claim.uuid,
                       "doi" => claim.doi,
                       "source_id" => claim.source_id } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(400)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>400, "title"=>"Orcid can't be blank"}])
      end
    end

    context "without doi" do
      let(:params) do
        { "claim" => { "uuid" => claim.uuid,
                       "orcid" => claim.orcid,
                       "source_id" => claim.source_id } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(400)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>400, "title"=>"Doi can't be blank"}])
      end
    end

    context "without source_id" do
      let(:params) do
        { "claim" => { "uuid" => claim.uuid,
                       "orcid" => claim.orcid,
                       "doi" => claim.doi } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(400)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>400, "title"=>"Source can't be blank"}])
      end
    end

    context "with wrong API key" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json; version=1",
          "HTTP_AUTHORIZATION" => "Token token=12345678" }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "with missing claim param" do
      let(:params) do
        { "data" => { "uuid" => claim.uuid,
                       "orcid" => claim.orcid,
                       "doi" => claim.doi,
                       "source_id" => claim.source_id } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(400)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"400", "title"=>"param is missing or the value is empty: claim"}])
      end
    end

    context "with unpermitted params" do
      let(:params) do
        { "claim" => { "uuid" => claim.uuid,
                       "orcid" => claim.orcid,
                       "doi" => claim.doi,
                       "source_id" => claim.source_id,
                       "foo" => "bar" } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"422", "title"=>"found unpermitted parameter: foo"}])
      end
    end

    context "with params in wrong format" do
      let(:params) { { "claim" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)
        response = JSON.parse(last_response.body)
        expect(response["errors"].first["title"]).to start_with("undefined method")
      end
    end
  end

  context "show" do
    let(:claim) { FactoryGirl.create(:claim) }
    let(:uri) { "/api/claims/#{claim.uuid}" }

    context "as admin user" do
      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response["data"]).to eq(success)
      end
    end

    context "as staff user" do
      let(:user) { FactoryGirl.create(:user, role: "staff") }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response["data"]).to eq(success)
      end
    end

    context "as regular user" do
      let(:user) { FactoryGirl.create(:user, role: "user") }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq (error)
      end
    end

    context "with wrong API key" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json; version=1",
          "HTTP_AUTHORIZATION" => "Token token=12345678" }
      end

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "claim not found" do
      let(:uri) { "/api/claims/#{claim.uuid}x" }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(404)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"404", "title"=>"The page you are looking for doesn't exist."}])
      end
    end
  end

  context "destroy" do
    let(:claim) { FactoryGirl.create(:claim) }
    let(:uri) { "/api/claims/#{claim.uuid}" }

    context "as admin user" do
      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response).to eq("data"=>{})
      end
    end

    context "as staff user" do
      let(:user) { FactoryGirl.create(:user, role: "staff") }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "as regular user" do
      let(:user) { FactoryGirl.create(:user, role: "user") }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "with wrong API key" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json; version=1",
          "HTTP_AUTHORIZATION" => "Token token=12345678" }
      end

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "claim not found" do
      let(:uri) { "/api/claims/#{claim.uuid}x" }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(404)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"404", "title"=>"The page you are looking for doesn't exist."}])
      end
    end
  end
end