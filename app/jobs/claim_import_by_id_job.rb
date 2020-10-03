class ClaimImportByIdJob < ActiveJob::Base
  queue_as :volpino

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(options={})
    Claim.import_by_id(options)
  end
end
