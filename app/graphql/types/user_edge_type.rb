# frozen_string_literal: true

class UserEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(UserType)
end
