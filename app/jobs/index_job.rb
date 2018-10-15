class IndexJob < ActiveJob::Base
  queue_as :lagottino

  def perform(obj)
    logger = Logger.new(STDOUT)
    obj.__elasticsearch__.index_document
    logger.info "Indexing event #{obj.uuid}."
  end
end