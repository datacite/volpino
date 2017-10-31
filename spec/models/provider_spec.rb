require 'rails_helper'

describe Provider, type: :model, vcr: true do
  it "providers" do
    providers = Provider.all[:data]
    expect(providers.length).to eq(54)
    provider = providers.first
    expect(provider.name).to eq("amazon jamon")
  end

  it "providers query" do
    providers = Provider.where(query: "data")[:data]
    expect(providers.length).to eq(3)
    provider = providers.first
    expect(provider.name).to eq("Australian National Data Service")
  end

  it "provider" do
    provider = Provider.where(id: "ands")[:data]
    expect(provider.name).to eq("Australian National Data Service")
  end
end
