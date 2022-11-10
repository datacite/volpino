require "rails_helper"

RSpec.describe ClaimJob, type: :job, elasticsearch: true do
  let(:claim) { FactoryBot.create(:claim)}
  let(:job) { claim.queue_claim_job }

  it "enqueue jobs" do
    expect { job }.to change(enqueued_jobs, :size).by(4)
    claim_job = enqueued_jobs.first
    expect(claim_job[:job]).to eq(UserJob)
  end

  it "executes perform", vcr: true do
    expect(claim.state).to eq("waiting")
    perform_enqueued_jobs { job }
  end
end
