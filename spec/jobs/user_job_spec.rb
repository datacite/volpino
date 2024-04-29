# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserJob, type: :job, elasticsearch: true do
  let!(:user) { FactoryBot.create(:valid_user) }
  let!(:job) { user.queue_user_job }

  it "enqueue jobs" do
    expect(UserJob).to(have_been_enqueued.at_least(:once))
  end
end
