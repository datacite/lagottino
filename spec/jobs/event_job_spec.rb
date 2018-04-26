require 'rails_helper'

RSpec.describe EventJob, :type => :job do
  include ActiveJob::TestHelper

  let(:event) { create(:event) }

  it "enqueue jobs" do
    expect(event.state?).to eq("waiting")
    expect(enqueued_jobs.size).to eq(1)

    event_job = enqueued_jobs.first
    expect(event_job[:job]).to eq(DepositJob)
  end
end
