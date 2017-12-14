require "rails_helper"

describe Member, type: :model, vcr: true do

  subject { FactoryBot.create(:member) }

  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_presence_of(:country_code) }
  it { is_expected.to validate_presence_of(:year) }

  it "has an institution_type" do
    subject = FactoryBot.create(:member, institution_type: "academic_institution")
    expect(subject.institution_type).to eq("academic_institution")
  end

  it "raise validation error on invalid institution_type" do
    expect { FactoryBot.create(:member, institution_type: "restaurant") }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Institution type Institution type %s is not included in the list")
  end
end
