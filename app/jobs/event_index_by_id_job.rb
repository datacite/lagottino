class EventIndexByIdJob < ActiveJob::Base
  queue_as :lagottino

  def perform(options={})
    Event.index_by_id(options)
  end
end