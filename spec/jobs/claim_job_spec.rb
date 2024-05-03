# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimJob, type: :job, elasticsearch: true do
  let!(:claim) { FactoryBot.create(:claim) }
  let!(:job) { claim.queue_claim_job }

  it "enqueue jobs" do
    expect(UserJob).to(have_been_enqueued.at_least(:once))
  end
end
