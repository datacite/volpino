require "rails_helper"

describe "/claims", type: :request, elasticsearch: true do
  before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8)) }

  let(:claim) { FactoryBot.create(:claim, uuid: "c7a026ca-51f9-4be9-b3fb-c15580f98e58", orcid: "0000-0002-1825-0097") }
  let(:error) { { "errors" => [{"status"=>"401", "title"=>"Bad credentials."}] } }
  let(:user) { FactoryBot.create(:admin_user, uid: "0000-0002-1825-0097") }
  let(:uuid) { SecureRandom.uuid }
  let(:headers) do
    { "HTTP_ACCEPT" => "application/json; version=1",
      "HTTP_AUTHORIZATION" => "Bearer #{user.jwt}" }
  end

  context "create with doi" do
    let(:uri) { "/claims" }
    let(:doi) { "10.23725/bc11-cqw8" }
    let(:params) do
      { "claim" => { "uuid" => uuid,
                     "orcid" => user.orcid,
                     "doi" => doi,
                     "claim_action" => "create",
                     "source_id" => "orcid_search" } }
    end

    before do
      Claim.import
      sleep 1
    end

    it "admin user" do
      post uri, params, headers

      expect(last_response.status).to eq(202)
      response = JSON.parse(last_response.body)
      expect(response["errors"]).to be_nil
      expect(response.dig("data", "attributes", "orcid")).to eq("https://orcid.org/0000-0002-1825-0097")
      expect(response.dig("data", "attributes", "doi")).to eq("https://doi.org/10.23725/bc11-cqw8")
      expect(response.dig("data", "attributes", "sourceId")).to eq("orcid_search")
      expect(response.dig("data", "attributes", "state")).to eq("waiting")
    end
  end

  context "create" do
    let(:uri) { "/claims" }
    let(:params) do
      { "claim" => { "uuid" => claim.uuid,
                     "orcid" => claim.orcid,
                     "doi" => claim.doi,
                     "claim_action" => "create",
                     "source_id" => claim.source_id } }
    end

    before do
      Claim.import
      sleep 1
    end

    context "as admin user" do
      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(202)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("data", "attributes", "orcid")).to start_with("https://orcid.org/0000-0002-1825-000")
        expect(response.dig("data", "attributes", "doi")).to eq("https://doi.org/10.5061/DRYAD.781PV")
        expect(response.dig("data", "attributes", "sourceId")).to eq("orcid_update")
        expect(response.dig("data", "attributes", "state")).to eq("waiting")
      end
    end

    context "as staff user" do
      let(:user) { FactoryBot.create(:staff_user) }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(403)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
      end
    end

    context "as regular user" do
      let(:user) { FactoryBot.create(:regular_user) }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(403)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
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
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"source"=>"user", "title"=>"Must exist"}])
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
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"source"=>"doi", "title"=>"Can't be blank"}])
      end
    end

    context "without source_id" do
      let(:claim) { FactoryBot.build(:claim, uuid: "c7a026ca-51f9-4be9-b3fb-c15580f98e58", orcid: "0000-0002-1825-0097", source_id: nil) }
      let(:params) do
        { "claim" => { "uuid" => claim.uuid,
                       "orcid" => claim.orcid,
                       "doi" => claim.doi } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"source"=>"source_id", "title"=>"Can't be blank"}])
      end
    end

    context "with wrong API key" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json; version=1",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
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
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"source"=>"user", "title"=>"Must exist"}])
      end
    end

    context "with params in wrong format" do
      let(:params) { { "claim" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(400)
        response = JSON.parse(last_response.body)
        expect(response["errors"].first["title"]).to start_with("undefined method")
      end
    end
  end

  context "index" do
    let!(:claim) { FactoryBot.create(:claim, uuid: "c7a026ca-51f9-4be9-b3fb-c15580f98e58", orcid: user.uid) }
    let(:uri) { "/claims" }

    before do
      Claim.import
      sleep 1
    end

    context "as admin user" do
      it "JSON" do
        get uri, nil, headers
        
        expect(last_response.status).to eq(200)
        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        item = response["data"].first
        expect(item.dig('attributes', 'doi')).to eq("https://doi.org/10.5061/DRYAD.781PV")
      end
    end

    context "as staff user" do
      let(:user) { FactoryBot.create(:staff_user) }
      let!(:claim) { FactoryBot.create(:claim, uuid: "c7a026ca-51f9-4be9-b3fb-c15580f98e58", orcid: user.uid) }
    
      it "JSON" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)
        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        item = response["data"].first
        expect(item.dig('attributes', 'doi')).to eq("https://doi.org/10.5061/DRYAD.781PV")
      end
    end

    context "as regular user" do
      let(:user) { FactoryBot.create(:regular_user) }
      let!(:claim) { FactoryBot.create(:claim, uuid: "c7a026ca-51f9-4be9-b3fb-c15580f98e58", orcid: user.uid) }
    
      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)
    
        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        item = response["data"].first
        expect(item.dig('attributes', 'doi')).to eq("https://doi.org/10.5061/DRYAD.781PV")
      end
    end

    context "with wrong API key" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json; version=1",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "with query for dois" do
      let(:doi) { "10.5061/DRYAD.781PV" }
      let(:uri) { "/claims?dois=#{doi}" }
    
      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)
    
        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        item = response["data"].first
        expect(item.dig('attributes', 'doi')).to eq("https://doi.org/10.5061/DRYAD.781PV")
      end
    end

    context "with query for missing dois" do
      let(:doi) { "10.5061/DRYAD.781PVx" }
      let(:uri) { "/claims?dois=#{doi}" }
    
      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)
    
        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response["data"]).to be_empty
        expect(response["meta"]).to eq("page"=>1, "total"=>0, "totalPages"=>0)
      end
    end
  end

  context "show" do
    let(:claim) { FactoryBot.create(:claim, uuid: "c7a026ca-51f9-4be9-b3fb-c15580f98e58", orcid: user.uid) }
    let(:uri) { "/claims/#{claim.uuid}" }

    before do
      Claim.import
      sleep 1
    end

    context "as admin user" do
      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("data", "attributes", "orcid")).to start_with("https://orcid.org/0000-0002-1825-000")
        expect(response.dig("data", "attributes", "doi")).to eq("https://doi.org/10.5061/DRYAD.781PV")
        expect(response.dig("data", "attributes", "sourceId")).to eq("orcid_update")
        expect(response.dig("data", "attributes", "state")).to eq("waiting")
      end
    end

    context "as staff user" do
      let(:user) { FactoryBot.create(:staff_user) }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("data", "attributes", "orcid")).to start_with("https://orcid.org/0000-0002-1825-000")
        expect(response.dig("data", "attributes", "doi")).to eq("https://doi.org/10.5061/DRYAD.781PV")
        expect(response.dig("data", "attributes", "sourceId")).to eq("orcid_update")
        expect(response.dig("data", "attributes", "state")).to eq("waiting")
      end
    end

    context "as regular user" do
      let(:user) { FactoryBot.create(:regular_user) }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("data", "attributes", "orcid")).to start_with("https://orcid.org/0000-0002-1825-000")
        expect(response.dig("data", "attributes", "doi")).to eq("https://doi.org/10.5061/DRYAD.781PV")
        expect(response.dig("data", "attributes", "sourceId")).to eq("orcid_update")
        expect(response.dig("data", "attributes", "state")).to eq("waiting")
      end
    end

    context "with wrong API key" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json; version=1",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "claim not found" do
      let(:uri) { "/claims/#{claim.uuid}x" }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(404)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end
  end

  context "delete" do
    let(:claim) { FactoryBot.create(:claim) }
    let(:uri) { "/claims/#{claim.uuid}" }

    before do
      Claim.import
      sleep 1
    end

    context "as admin user" do
      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response).to eq("data"=>{})
      end
    end

    context "as staff user" do
      let(:user) { FactoryBot.create(:staff_user) }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(403)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"403", "title"=>"You are not authorized to access this resource."}])
      end
    end

    # context "as regular user" do
    #   let(:user) { FactoryBot.create(:regular_user) }

    #   it "JSON" do
    #     delete uri, nil, headers
    #     expect(last_response.status).to eq(401)

    #     response = JSON.parse(last_response.body)
    #     expect(response).to eq(error)
    #   end
    # end

    context "with wrong API key" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json; version=1",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response).to eq(error)
      end
    end

    context "claim not found" do
      let(:uri) { "/claims/#{claim.uuid}x" }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(404)

        response = JSON.parse(last_response.body)
        expect(response).to eq("errors"=>[{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end
  end
end
