class EventIndexByDayJob < ActiveJob::Base
  queue_as :lagottino

  def perform(options={})
    Event.index_by_day(options)
  end
end