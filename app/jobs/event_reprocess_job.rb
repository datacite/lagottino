class EventReprocessJob < ActiveJob::Base
  queue_as :lagottino

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError do
    retry_job wait: 5.minutes, queue: :lagottino
  end

  def perform(ids)
    ActiveRecord::Base.connection_pool.with_connection do
      Event.where(id: ids).find_each { |event| event.reset }
    end
  end
end