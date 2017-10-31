require 'rails_helper'

describe OrcidUser, type: :model, vcr: true do
  it "orcid_users query name" do
    orcid_users = OrcidUser.where(query: "fenner")[:data]
    expect(orcid_users.length).to eq(4)
    orcid_user = orcid_users.first
    expect(orcid_user.name).to eq("Martin Fenner")
  end

  it "orcid_users query orcid id" do
    orcid_users = OrcidUser.where(query: "0000-0001-6528-2027")[:data]
    expect(orcid_users.length).to eq(25)
    orcid_user = orcid_users.first
    expect(orcid_user.name).to eq("Martin Fenner")
  end
end
