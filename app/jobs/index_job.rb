class IndexJob < ActiveJob::Base
  queue_as :lupo

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    logger = Logger.new(STDOUT)
    logger.error error.message
  end

  def perform(obj)
    obj.__elasticsearch__.index_document
  end
end
