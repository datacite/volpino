# frozen_string_literal: true

module Facetable
  extend ActiveSupport::Concern

  included do
    def facet_by_year(arr)
      arr.map do |hsh|
        { "id" => hsh["key_as_string"][0..3],
          "title" => hsh["key_as_string"][0..3],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_date(arr)
      arr.map do |hsh|
        { "id" => hsh["key"][0..9],
          "title" => hsh["key"][0..9],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_key(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"].titleize,
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_id(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"] }
      end
    end
  end
end
