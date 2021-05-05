require "rails_helper"

RSpec.describe ClaimJob, type: :job, elasticsearch: true do
  let(:user) { FactoryBot.create(:user) }
  let(:claim) { FactoryBot.create(:claim, orcid: user.uid) }
  let(:job) { claim.queue_claim_job }

  it "enqueue jobs" do
    expect { job }.to change(enqueued_jobs, :size).by(7)

    claim_job = enqueued_jobs.first
    expect(claim_job[:job]).to eq(UserJob)
  end

  it "executes perform", vcr: true do
    expect(claim.state).to eq("waiting")
    perform_enqueued_jobs { job }
  end
end
