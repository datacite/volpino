require 'rails_helper'

RSpec.describe ClaimJob, :type => :job do
  let(:user) { FactoryGirl.create(:user) }
  let(:claim) { FactoryGirl.create(:claim, orcid: user.uid) }
  let(:job) { claim.queue_claim_job }

  it "enqueue jobs" do
    expect { job }.to change(enqueued_jobs, :size).by(1)

    claim_job = enqueued_jobs.first
    expect(claim_job[:job]).to eq(ClaimJob)
  end

  it 'executes perform', vcr: true do
    expect(claim.human_state_name).to eq("waiting")
    perform_enqueued_jobs { job }
  end
end
