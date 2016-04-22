require 'rails_helper'

describe "deposit:all", vcr: true, rake: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let(:user) { FactoryGirl.create(:user, uid: "0000-0003-1419-2405") }
  let(:claim) { FactoryGirl.create(:claim, user: user, orcid: "0000-0003-1419-2405", doi: "10.5281/ZENODO.21429") }

  let!(:output) { "Importing claim #{claim.doi} for user #{user.uid}.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end
