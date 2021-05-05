require "rails_helper"

describe Claim, type: :model, vcr: true, elasticsearch: true do
  subject { FactoryBot.create(:claim) }

  context "HTTP" do
    let(:url) { "http://127.0.0.1/api/claims/#{subject.uuid}" }
    let(:data) { { "name" => "Fred" } }
    let(:post_data) { { "name" => "Jack" } }

    context "clean identifiers" do
      let(:url) { "http://journals.PLOS.org/plosone/article?id=10.1371%2Fjournal.pone.0000030&utm_source=FeedBurner#stuff" }
      let(:doi) { "10.5061/dryad.8515" }
      let(:id) { "http://doi.org/10.5061/dryad.8515" }

      it "get_normalized_url" do
        response = subject.get_normalized_url(url)
        expect(response).to eq("http://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0000030")
      end

      it "get_normalized_url invalid url" do
        url = "article?id=10.1371%2Fjournal.pone.0000030"
        response = subject.get_normalized_url(url)
        expect(response).to be_nil
      end

      it "doi_as_url" do
        response = subject.doi_as_url(doi)
        expect(response).to eq("http://doi.org/10.5061/dryad.8515")
      end

      it "get_doi_from_id" do
        response = subject.get_doi_from_id(id)
        expect(response).to eq("10.5061/dryad.8515")
      end

      it "get_doi_from_id https" do
        id = "https://doi.org/10.5061/dryad.8515"
        response = subject.get_doi_from_id(id)
        expect(response).to eq("10.5061/dryad.8515")
      end

      it "get_doi_from_id dx.doi.org" do
        id = "http://dx.doi.org/10.5061/dryad.8515"
        response = subject.get_doi_from_id(id)
        expect(response).to eq("10.5061/dryad.8515")
      end
    end
  end
end
