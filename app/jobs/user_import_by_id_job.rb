class UserImportByIdJob < ApplicationJob
  queue_as :volpino

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(options = {})
    User.import_by_id(options)
  end
end
