# frozen_string_literal: true

require "rails_helper"

describe Metadatable, vcr: true, order: :defined do
  let(:orcid) { "0000-0001-6528-2027" }

  context "class_methods" do
    subject { UsersController }

    context "create_metadata" do
      it "get_orcid_metadata" do
        expect(subject.get_orcid_metadata(orcid)).to eq(family_name: "Fenner", given_names: "Martin", name: "Martin Fenner")
      end
    end
  end
end
