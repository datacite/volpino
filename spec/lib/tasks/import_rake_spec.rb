require 'rails_helper'

describe "import:all", vcr: true, rake: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let(:user) { FactoryBot.create(:user, uid: "0000-0003-1419-2405") }
  let!(:output) { "Importing works for user #{user.uid}.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  # it "should run" do
  #   expect(capture_stdout { subject.invoke }).to eq(output)
  # end
end

describe "import:one", vcr: true, rake: true do
  include ActiveJob::TestHelper
  include WithEnv
  include_context "rake"

  let(:user) { FactoryBot.create(:user, uid: "0000-0003-1419-2405") }
  let!(:output) { "Importing works for user #{user.uid}.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run" do
    with_env("ORCID" => "0000-0003-1419-2405") do
      expect(capture_stdout { subject.invoke }).to eq(output)
    end
  end
end
