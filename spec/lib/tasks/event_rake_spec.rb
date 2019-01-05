require 'rails_helper'

describe "event:index", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  ENV['FROM_ID'] = "1"
  ENV['UNTIL_ID'] = "1000"

  let!(:event) { create_list(:event, 10) }
  let(:output) { "Queued indexing for events with IDs starting with 1.\nQueued indexing for events with IDs starting with 501.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end

  it "should enqueue an EventIndexByIdJob" do
    expect {
      capture_stdout { subject.invoke }
    }.to change(enqueued_jobs, :size).by(2)
    expect(enqueued_jobs.last[:job]).to be(EventIndexByIdJob)
  end
end
