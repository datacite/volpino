# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserJob, type: :job, elasticsearch: true do
  it "enqueue jobs" do
    perform_enqueued_jobs do
      FactoryBot.create(:valid_user).queue_user_job
      expect(UserJob).to(have_been_enqueued.at_least(:once))
    end
  end

  it "executes perform", vcr: true do
    perform_enqueued_jobs do
      expect(user.claims.count).to eq(0)
      user = FactoryBot.create(:valid_user)
      user.queue_user_job
      expect(user.claims.count).to eq(23)
    end
  end
end
