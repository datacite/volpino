require 'rails_helper'

describe UserSearch, type: :model, vcr: true do
  it "users query name" do
    users = UserSearch.where(query: "fenner")[:data]
    expect(users.length).to eq(4)
    user = users.first
    expect(user.name).to eq("0000-0002-8568-5429")
  end

  it "users query orcid id" do
    users = UserSearch.where(query: "0000-0001-6528-2027")[:data]
    expect(users.length).to eq(25)
    user = users.first
    expect(user.name).to eq("0000-0001-6528-2027")
  end

  it "users get orcid id" do
    user = UserSearch.where(id: "0000-0001-6528-2027")[:data]
    expect(user.name).to eq("Martin Fenner")
    expect(user.family_name).to eq("Fenner")
    expect(user.given_names).to eq("Martin")
    expect(user.uid).to eq("0000-0001-6528-2027")
  end
end
