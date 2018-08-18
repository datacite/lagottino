# class EventJob < ActiveJob::Base
#   queue_as :lagottino

#   rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError do
#     retry_job wait: 5.minutes, queue: :lagottino
#   end

#   def perform(event)
#     ActiveRecord::Base.connection_pool.with_connection do
#       event.process_data
#     end
#   end
# end