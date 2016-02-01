require "rails_helper"

describe Claim, type: :model, vcr: true do

  subject { FactoryGirl.create(:claim) }

  it { is_expected.to validate_presence_of(:uid) }
  it { is_expected.to validate_presence_of(:doi) }
  it { is_expected.to validate_presence_of(:source_id) }

  it 'contributors' do
    expect(subject.contributors).to eq([{:orcid=>nil, :credit_name=>"Heather A. Piwowar", :role=>nil}, {:orcid=>nil, :credit_name=>"Todd J. Vision", :role=>nil}])
  end

  it 'publication_date' do
    expect(subject.publication_date).to eq("year" => 2013)
  end

  it 'citation' do
    expect(subject.citation).to eq("@data{33e0b47a-1025-4b53-be59-73261147ee4e,  doi = {10.5061/DRYAD.781PV},  url = {http://dx.doi.org/10.5061/DRYAD.781PV},  author = {Piwowar, Heather A.; Vision, Todd J.; },  publisher = {Dryad Digital Repository},  title = {Data from: Data reuse and the open data citation advantage},  year = {2013}}")
  end

  it 'data' do
    xml = File.read(fixture_path + 'claim.xml')
    expect(subject.data).to eq(xml)
  end
end
