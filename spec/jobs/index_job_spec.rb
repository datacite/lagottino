require 'rails_helper'

describe IndexJob, type: :job do
  let(:event) { create(:event) }
  subject(:job) { IndexJob.perform_later(event) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(IndexJob)
      .on_queue("test_lagottino").at_least(1).times
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end