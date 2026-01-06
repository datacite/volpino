# frozen_string_literal: true

class VolpinoSchema < GraphQL::Schema
  include ApolloFederation::Schema

  use ApolloFederation::Tracing

  default_max_page_size 250
  max_depth 10

  # mutation(Types::MutationType)
  query(QueryType)

  use GraphQL::Batch

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    raise GraphQL::ExecutionError, "Record not found"
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    raise GraphQL::ExecutionError, exception.record.errors.full_messages.join("\n")
  end

  rescue_from StandardError do |exception|
    Raven.capture_exception(exception)
    message = Rails.env.production? ? "We are sorry, but an error has occured. This problem has been logged and support has been notified. Please try again later. If the error persists please contact support." : exception.message
    raise GraphQL::ExecutionError, message
  end
end
