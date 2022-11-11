# frozen_string_literal: true

## https://github.com/elastic/elasticsearch-ruby/issues/462
SEARCHABLE_MODELS = [Claim, User].freeze

RSpec.configure do |config|
  config.around :example, elasticsearch: true do |example|
    SEARCHABLE_MODELS.each do |model|
      if Elasticsearch::Model.client.indices.exists? index: model.index_name
        model.__elasticsearch__.create_index! force: true
      else
        model.__elasticsearch__.create_index!
      end
    end

    example.run

    SEARCHABLE_MODELS.each do |model|
      Elasticsearch::Model.client.indices.delete index: model.index_name
    end
  end
end
