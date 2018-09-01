require 'rails_helper'

describe "event:index", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  ENV['FROM_DATE'] = "2018-01-04"
  ENV['UNTIL_DATE'] = "2018-08-05"

  let!(:event)  { create_list(:event, 10) }
  let(:output) { "Queued indexing for events updated from 2018-01-01 until 2018-08-31.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end

  it "should enqueue an EventIndexByDayJob" do
    expect {
      capture_stdout { subject.invoke }
    }.to change(enqueued_jobs, :size).by(243)
    expect(enqueued_jobs.last[:job]).to be(EventIndexByDayJob)
  end
end

describe "event:index_by_day", elasticsearch: true do
  include ActiveJob::TestHelper
  include_context "rake"

  let!(:event)  { create_list(:event, 10) }
  let(:output) { "Events updated on 2018-01-04 indexed.\n" }

  it "prerequisites should include environment" do
    expect(subject.prerequisites).to include("environment")
  end

  it "should run the rake task" do
    expect(capture_stdout { subject.invoke }).to eq(output)
  end
end