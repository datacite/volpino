# frozen_string_literal: true

module Resolvable
  extend ActiveSupport::Concern

  included do
    require "addressable/uri"

    def get_normalized_url(url)
      uri = Addressable::URI.parse(url)
      uri.normalize!

      if uri.query_values
        uri.query_values = uri.query_values.reject do |k, _|
          k.match?(/^utm_|^ref$|^source$/)
        end
      end

      uri.fragment = nil # optional: remove #stuff

      uri.to_s
    rescue Addressable::URI::InvalidURIError
      nil
    end

    def doi_as_url(doi)
      Addressable::URI.encode("http://doi.org/#{doi}") if doi.present?
    end

    def orcid_as_url(orcid)
      "http://orcid.org/#{orcid}" if orcid.present?
    end

    def github_as_url(github)
      "https://github.com/#{github}" if github.present?
    end

    def get_doi_from_id(id)
      if /(http|https):\/\/(dx\.)?doi\.org\/(\w+)/.match?(id)
        uri = Addressable::URI.parse(id)
        uri.path[1..-1]
      elsif id.starts_with?("doi:")
        id[4..-1]
      end
    end
  end
end
