# frozen_string_literal: true

module Indexable
  extend ActiveSupport::Concern

  require "aws-sdk-sqs"

  included do
    after_commit on: %i[create update] do
      # use index_document instead of update_document to also update virtual attributes
      IndexJob.perform_later(self)
    end

    after_touch do
      # use index_document instead of update_document to also update virtual attributes
      IndexJob.perform_later(self)
    end

    before_destroy do
      __elasticsearch__.delete_document
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end
  end

  module ClassMethods
    # return results for one or more ids
    def self.find_by_id(ids, options = {})
      ids = ids.split(",") if ids.is_a?(String)

      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 1000
      options[:sort] ||= { created_at: { order: "asc" } }

      __elasticsearch__.search(
        from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
        size: options.dig(:page, :size),
        sort: [options[:sort]],
        track_total_hits: true,
        query: {
          terms: {
            uid: ids,
          },
        },
        aggregations: query_aggregations,
      )
    end

    def query_aggregations
      {}
    end

    def find_by_id_list(ids, options = {})
      options[:sort] ||= { "_doc" => { order: "asc" } }

      __elasticsearch__.search(
        from: options[:page].present? ? (options.dig(:page, :number) - 1) * options.dig(:page, :size) : 0,
        size: options[:size] || 25,
        sort: [options[:sort]],
        track_total_hits: true,
        query: {
          terms: {
            id: ids.split(","),
          },
        },
        aggregations: query_aggregations,
      )
    end

    def get_aggregations_hash(aggregations = "")
      return send(:query_aggregations) if aggregations.blank?

      aggs = {}
      aggregations.split(",").each do |agg|
        agg = :query_aggregations if agg.blank? || !respond_to?(agg)
        aggs.merge! send(agg)
      end
      aggs
    end

    def query(query, options = {})
      aggregations = options[:totals_agg] == true ? totals_aggregations : get_aggregations_hash(options[:aggregations])
      options[:page] ||= {}
      options[:page][:number] ||= 1
      options[:page][:size] ||= 25

      # Cursor nav use the search after, this should always be an array of values that match the sort.
      if options.dig(:page, :cursor)
        from = 0

        # make sure we have a valid cursor
        search_after = options.dig(:page, :cursor).presence || [1, "1"]

        if name == "Claim"
          sort = [{ created: "asc", uuid: "asc" }]
        elsif name == "User"
          sort = [{ created: "asc", uid: "asc" }]
        end
      else
        from = ((options.dig(:page, :number) || 1).to_i - 1) * (options.dig(:page, :size) || 25).to_i
        search_after = nil
        sort = options[:sort]
      end

      if query.present?
        query = query.gsub("/", '\/')
      end

      must = []
      must << { query_string: { query: query, fields: query_fields } } if query.present?
      must << { range: { updated: { gte: "#{options[:updated].split(',').min}||/y", lte: "#{options[:updated].split(',').max}||/y", format: "yyyy" } } } if options[:updated].present?
      must << { range: { created: { gte: "#{options[:created].split(',').min}||/y", lte: "#{options[:created].split(',').max}||/y", format: "yyyy" } } } if options[:created].present?

      must_not = []

      # filters for some classes
      if name == "Claim"
        must << { terms: { doi: options[:dois].to_s.split(",") } } if options[:dois].present?
        must << { term: { user_id: options[:user_id] } } if options[:user_id].present?
        must << { term: { source_id: options[:source_id] } } if options[:source_id].present?
        must << { term: { claim_action: options[:claim_action] } } if options[:claim_action].present?
        must << { terms: { aasm_state: options[:state].to_s.split(",") } } if options[:state].present?
        must << { range: { claimed: { gte: "#{options[:claimed].split(',').min}||/y", lte: "#{options[:claimed].split(',').max}||/y", format: "yyyy" } } } if options[:claimed].present?
      elsif name == "User"
        must << { term: { role_id: options[:role_id] } } if options[:role_id].present?
      end

      # ES query can be optionally defined in different ways
      # So here we build it differently based upon options
      # This is mostly useful when trying to wrap it in a function_score query
      es_query = {}

      # The main bool query with filters
      bool_query = {
        must: must,
        must_not: must_not,
      }

      # Function score is used to provide varying score to return different values
      # We use the bool query above as our principle query
      # Then apply additional function scoring as appropriate
      # Note this can be performance intensive.
      function_score = {
        query: {
          bool: bool_query,
        },
        random_score: {
          "seed": Rails.env.test? ? "random_1234" : "random_#{rand(1...100000)}",
        },
      }

      if options[:random].present?
        es_query["function_score"] = function_score
        # Don't do any sorting for random results
        sort = nil
      else
        es_query["bool"] = bool_query
      end

      # Sample grouping is optional included aggregation
      if options[:sample_group].present?
        aggregations[:samples] = {
          terms: {
            field: options[:sample_group],
            size: 10000,
          },
          aggs: {
            "samples_hits": {
              top_hits: {
                size: options[:sample_size].presence || 1,
              },
            },
          },
        }
      end

      __elasticsearch__.search({
        size: options.dig(:page, :size),
        from: from,
        search_after: search_after,
        sort: sort,
        track_total_hits: true,
        query: es_query,
        aggregations: aggregations,
      }.compact)
    end

    def recreate_index(options = {})
      client     = gateway.client
      index_name = self.index_name

      if options[:force]
        begin
          client.indices.delete index: index_name
        rescue StandardError
          nil
        end
      end
      client.indices.create index: index_name, body: { settings: { "index.requests.cache.enable": true } }
    end

    def count
      Elasticsearch::Model.client.count(index: index_name)["count"]
    end

    # Aliasing
    #
    # We are using two indexes, where one is active (used for API calls) via aliasing and the other one
    # is inactive. All index configuration changes and bulk importing from the database
    # happen in the inactive index.
    #
    # For initial setup run "create_index" to start from scratch.
    #
    # Run "upgrade_index" whenever there are changes in the mappings or settings.
    # Follow this by "import" to fill the new index, the usen "switch_index" to
    # alias the new index and remove alias from current index.
    #
    # TODO: automatically switch aliases when "import" is done. Not easy, as "import"
    # runs as background jobs.

    # track reindexing via the tasks API
    def monitor_reindex
      client = Elasticsearch::Model.client
      tasks = client.tasks.list(actions: "*reindex")
      tasks.fetch("nodes", {}).inspect
    end

    # create alias
    def create_alias(options = {})
      alias_name = options[:alias] || index_name
      index_name = options[:index] || self.index_name + "_v1"
      # alternate_index_name = options[:index] || self.index_name + "_v2"

      client = Elasticsearch::Model.client

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_index_name])
      #     "Alias #{alias_name} for index #{datacite_index_name} already exists."
      #   else
      #     client.indices.put_alias index: datacite_index_name, name: alias_name
      #     "Created alias #{alias_name} for index #{datacite_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_index_name])
      #     "Alias #{alias_name} for index #{other_index_name} already exists."
      #   else
      #     client.indices.put_alias index: other_index_name, name: alias_name
      #     "Created alias #{alias_name} for index #{other_index_name}."
      #   end
      # else
      if client.indices.exists_alias?(name: alias_name, index: [index_name])
        "Alias #{alias_name} for index #{index_name} already exists."
      else
        # alias index is writeable unless it is for OtherDoi index
        client.indices.update_aliases(
          body: {
            actions: [
              {
                add: {
                  index: index_name,
                  alias: alias_name,
                  is_write_index: name != "OtherDoi",
                },
              },
            ],
          },
        )

        "Created alias #{alias_name} for index #{index_name}."
      end
      # end
    end

    # list all aliases
    def list_aliases
      client = Elasticsearch::Model.client
      cat_client = Elasticsearch::API::Cat::CatClient.new(client)
      puts cat_client.aliases(s: "alias")
    end

    # delete alias
    def delete_alias(options = {})
      alias_name = options[:alias] || index_name
      index_name = (options[:index] || self.index_name) + "_v1"
      alternate_index_name = (options[:index] || self.index_name) + "_v2"

      client = Elasticsearch::Model.client

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_index_name])
      #     client.indices.delete_alias index: datacite_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{datacite_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [datacite_alternate_index_name])
      #     client.indices.delete_alias index: datacite_alternate_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{datacite_alternate_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_index_name])
      #     client.indices.delete_alias index: other_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{other_index_name}."
      #   end
      #   if client.indices.exists_alias?(name: alias_name, index: [other_alternate_index_name])
      #     client.indices.delete_alias index: other_alternate_index_name, name: alias_name
      #     "Deleted alias #{alias_name} for index #{other_alternate_index_name}."
      #   end
      # else
      if client.indices.exists_alias?(name: alias_name, index: [index_name])
        client.indices.delete_alias index: index_name, name: alias_name
        "Deleted alias #{alias_name} for index #{index_name}."
      end
      if client.indices.exists_alias?(
        name: alias_name, index: [alternate_index_name],
      )
        client.indices.delete_alias index: alternate_index_name,
                                    name: alias_name
        "Deleted alias #{alias_name} for index #{alternate_index_name}."
      end
      # end
    end

    # create both indexes used for aliasing
    def create_index(options = {})
      alias_name = options[:alias] || index_name
      index_name = (options[:index] || self.index_name) + "_v1"
      alternate_index_name = (options[:index] || self.index_name) + "_v2"
      client = Elasticsearch::Model.client

      # delete index if it has the same name as the alias
      if __elasticsearch__.index_exists?(index: alias_name) &&
          !client.indices.exists_alias?(name: alias_name)
        __elasticsearch__.delete_index!(index: alias_name)
      end

      create_template if name == "DataciteDoi" || name == "OtherDoi"

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   self.__elasticsearch__.create_index!(index: datacite_index_name) unless self.__elasticsearch__.index_exists?(index: datacite_index_name)
      #   self.__elasticsearch__.create_index!(index: datacite_alternate_index_name) unless self.__elasticsearch__.index_exists?(index: datacite_alternate_index_name)
      #   self.__elasticsearch__.create_index!(index: other_index_name) unless self.__elasticsearch__.index_exists?(index: other_index_name)
      #   self.__elasticsearch__.create_index!(index: other_alternate_index_name) unless self.__elasticsearch__.index_exists?(index: other_alternate_index_name)

      #   "Created indexes #{datacite_index_name}, #{other_index_name}, #{datacite_alternate_index_name}, and #{other_alternate_index_name}."
      # else
      unless __elasticsearch__.index_exists?(index: index_name)
        __elasticsearch__.create_index!(index: index_name)
      end
      unless __elasticsearch__.index_exists?(index: alternate_index_name)
        __elasticsearch__.create_index!(index: alternate_index_name)
      end

      "Created indexes #{index_name} and #{alternate_index_name}."
      # end
    end

    # delete index and both indexes used for aliasing
    def delete_index(options = {})
      # client = Elasticsearch::Model.client

      if options[:index]
        __elasticsearch__.delete_index!(index: options[:index])
        return "Deleted index #{options[:index]}."
      end

      # alias_name = index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      # indexes in DOI model are aliased from DataciteDoi and OtherDoi models
      # TODO switch to DataciteDoi index
      # if self.name == "Doi"
      #   datacite_index_name = DataciteDoi.index_name + "_v1"
      #   datacite_alternate_index_name = DataciteDoi.index_name + "_v2"
      #   other_index_name = OtherDoi.index_name + "_v1"
      #   other_alternate_index_name = OtherDoi.index_name + "_v2"

      #   self.__elasticsearch__.delete_index!(index: datacite_index_name) if self.__elasticsearch__.index_exists?(index: datacite_index_name)
      #   self.__elasticsearch__.delete_index!(index: datacite_alternate_index_name) if self.__elasticsearch__.index_exists?(index: datacite_alternate_index_name)
      #   self.__elasticsearch__.delete_index!(index: other_index_name) if self.__elasticsearch__.index_exists?(index: other_index_name)
      #   self.__elasticsearch__.delete_index!(index: other_alternate_index_name) if self.__elasticsearch__.index_exists?(index: other_alternate_index_name)

      #   "Deleted indexes #{datacite_index_name}, #{other_index_name}, #{datacite_alternate_index_name}, and #{other_alternate_index_name}."
      # else
      if __elasticsearch__.index_exists?(index: index_name)
        __elasticsearch__.delete_index!(index: index_name)
      end
      if __elasticsearch__.index_exists?(index: alternate_index_name)
        __elasticsearch__.delete_index!(index: alternate_index_name)
      end

      "Deleted indexes #{index_name} and #{alternate_index_name}."
      # end
    end

    # delete and create inactive index to use current mappings
    # Needs to run every time we change the mappings
    def upgrade_index
      inactive_index ||= inactive_index

      __elasticsearch__.delete_index!(index: inactive_index) if __elasticsearch__.index_exists?(index: inactive_index)

      if __elasticsearch__.index_exists?(index: inactive_index)
        "Error: inactive index #{inactive_index} could not be upgraded."
      else
        __elasticsearch__.create_index!(index: inactive_index)
        "Upgraded inactive index #{inactive_index}."
      end
    end

    # show stats for both indexes
    def index_stats(_options = {})
      active_index = self.active_index
      inactive_index = self.inactive_index

      client = Elasticsearch::Model.client
      stats = client.indices.stats index: [active_index, inactive_index], docs: true
      active_index_count = stats.dig("indices", active_index, "primaries", "docs", "count")
      inactive_index_count = stats.dig("indices", inactive_index, "primaries", "docs", "count")
      database_count = all.count

      message = "Active index #{active_index} has #{active_index_count} documents, " \
        "inactive index #{inactive_index} has #{inactive_index_count} documents, " \
        "database has #{database_count} documents."
      message
    end

    # switch between the two indexes, i.e. the index that is aliased
    def switch_index(_options = {})
      alias_name = index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      client = Elasticsearch::Model.client

      if client.indices.exists_alias?(name: alias_name, index: [index_name])
        client.indices.update_aliases body: {
          actions: [
            { remove: { index: index_name, alias: alias_name } },
            { add:    { index: alternate_index_name, alias: alias_name } },
          ],
        }

        "Switched active index to #{alternate_index_name}."
      elsif client.indices.exists_alias?(name: alias_name, index: [alternate_index_name])
        client.indices.update_aliases body: {
          actions: [
            { remove: { index: alternate_index_name, alias: alias_name } },
            { add:    { index: index_name, alias: alias_name } },
          ],
        }

        "Switched active index to #{index_name}."
      end
    end

    # Return the active index, i.e. the index that is aliased
    def active_index
      alias_name = index_name
      client = Elasticsearch::Model.client
      client.indices.get_alias(name: alias_name).keys.first
    end

    # Return the inactive index, i.e. the index that is not aliased
    def inactive_index
      alias_name = index_name
      index_name = self.index_name + "_v1"
      alternate_index_name = self.index_name + "_v2"

      client = Elasticsearch::Model.client
      active_index = client.indices.get_alias(name: alias_name).keys.first
      active_index.end_with?("v1") ? alternate_index_name : index_name
    end
  end
end
