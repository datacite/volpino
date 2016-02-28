require 'rails_helper'

RSpec.describe ClaimJob, :type => :job do
  include ActiveJob::TestHelper

  let(:user) { FactoryGirl.create(:user) }
  let(:claim) { FactoryGirl.create(:claim, orcid: user.uid) }

  it "enqueue jobs" do
    ClaimJob.perform_later(claim)
    expect(claim.human_state_name).to eq("waiting")
    expect(enqueued_jobs.size).to eq(1)

    claim_job = enqueued_jobs.first
    expect(claim_job[:job]).to eq(ClaimJob)
  end
end
