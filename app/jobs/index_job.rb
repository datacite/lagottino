class IndexJob < ActiveJob::Base
  queue_as :lagottino

  def perform(obj)
    obj.__elasticsearch__.index_document
  end
end