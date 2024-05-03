# frozen_string_literal: true

require "rails_helper"

describe Work, type: :model, vcr: true, elasticsearch: true do
  let(:doi) { "10.5438/mk65-3m12" }
  let(:user) { FactoryBot.create(:valid_user) }
  let(:put_code) { "1069296" }

  subject { Work.new(doi: doi, orcid: user.uid, orcid_token: user.orcid_token, put_code: put_code) }

  describe "push to ORCID", order: :defined do
    describe "get" do
      it "should get works" do
        response = subject.get_works(sandbox: true)
        works = response.body.fetch("data", {}).fetch("group", {})
        expect(works.length).to eq(23)
        work = works.first
        expect(work["external-ids"]).to eq("external-id" => [{ "external-id-normalized" => { "transient" => true, "value" => "10.5256/f1000research.67475.r16884" }, "external-id-normalized-error" => nil, "external-id-relationship" => "self", "external-id-type" => "doi", "external-id-url" => nil, "external-id-value" => "10.5256/f1000research.67475.r16884" }])
      end
    end

    describe "delete" do
      it "should delete work" do
        response = subject.delete_work(sandbox: true)
        expect(response["data"]).to be_blank
        expect(response["errors"]).to be_nil
      end
    end
  end

  describe "schema" do
    it "exists" do
      expect(subject.schema.errors).to be_empty
    end

    it "validates data with errors" do
      allow(subject).to receive(:metadata) { OpenStruct.new }
      expect(subject.validation_errors).to eq(["-1:0: ERROR: The document has no document element."])
    end
  end
end
