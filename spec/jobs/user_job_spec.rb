require 'rails_helper'

RSpec.describe UserJob, :type => :job do
  let(:user) { FactoryGirl.create(:valid_user) }
  let(:job) { user.queue_user_job }

  it "enqueue jobs" do
    expect { job }.to change(enqueued_jobs, :size).by(1)

    user_job = enqueued_jobs.first
    expect(user_job[:job]).to eq(UserJob)
  end

  it 'executes perform', vcr: true do
    expect(user.claims.count).to eq(0)
    perform_enqueued_jobs { job }
    expect(user.claims.count).to eq(25)
  end
end
