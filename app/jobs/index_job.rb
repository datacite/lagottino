class IndexJob < ActiveJob::Base
  queue_as :lagottino

  def perform(obj)
    obj.__elasticsearch__.index_document
    Rails.logger.info "Indexing event #{obj.uuid}."
  end
end