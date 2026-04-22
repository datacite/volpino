# frozen_string_literal: true

class IndexJob < ApplicationJob
  queue_as :volpino

  rescue_from ActiveJob::DeserializationError, SocketError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(obj)
    obj.__elasticsearch__.index_document
  rescue SocketError
    # ignore missing Elasticsearch socket
  end
end
