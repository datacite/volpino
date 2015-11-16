module Resolvable
  extend ActiveSupport::Concern

  included do
    require "addressable/uri"

    def get_normalized_url(url)
      url = PostRank::URI.clean(url)
      if PostRank::URI.valid?(url)
        url
      end
    rescue Addressable::URI::InvalidURIError => e
      { error: e.message }
    end

    def doi_as_url(doi)
      Addressable::URI.encode("http://doi.org/#{doi}") if doi.present?
    end

    def get_doi_from_id(id)
      if /(http|https):\/\/(dx\.)?doi\.org\/(\w+)/.match(id)
        uri = Addressable::URI.parse(id)
        uri.path[1..-1]
      elsif id.starts_with?("doi:")
        id[4..-1]
      end
    end

    def get_metadata(id, service, options = {})
      case service
      when "crossref" then get_crossref_metadata(id, options = {})
      when "datacite" then get_datacite_metadata(id, options = {})
      when "orcid" then get_orcid_metadata(id, options = {})
      else
        { error: 'Resource not found.', status: 404 }
      end
    end

    def get_crossref_metadata(doi, options = {})
      return {} if doi.blank?

      conn = faraday_conn('json', options)
      url = "http://api.crossref.org/works/" + PostRank::URI.escape(doi)
      response = conn.get url, {}, options[:headers]

      if is_json?(response.body)
        json = JSON.parse(response.body)
        metadata = json.fetch("message", {})
        return { error: 'Resource not found.' } if metadata.blank?

        date_parts = metadata.fetch("issued", {}).fetch("date-parts", []).first
        year, month, day = date_parts[0], date_parts[1], date_parts[2]

        # use date indexed if date issued is in the future
        if year.nil? || Date.new(*date_parts) > Time.zone.now.to_date
          date_parts = metadata.fetch("indexed", {}).fetch("date-parts", []).first
          year, month, day = date_parts[0], date_parts[1], date_parts[2]
        end
        metadata["issued"] = { "date-parts" => [date_parts] }

        metadata["title"] = case metadata["title"].length
              when 0 then nil
              when 1 then metadata["title"][0]
              else metadata["title"][0].presence || metadata["title"][1]
              end

        if metadata["title"].blank? && !TYPES_WITH_TITLE.include?(metadata["type"])
          metadata["title"] = metadata["container-title"][0].presence || "No title"
        end

        metadata["container-title"] = metadata.fetch("container-title", [])[0]
        metadata["type"] = CROSSREF_TYPE_TRANSLATIONS[metadata["type"]] if metadata["type"]
        metadata["author"] = metadata["author"].map { |author| author.except("affiliation") }

        metadata
      else
        { error: 'Resource not found.', status: 404 }
      end
    rescue *NETWORKABLE_EXCEPTIONS => e
      rescue_faraday_error(url, e, options)
    end

    def get_datacite_metadata(doi, options = {})
      return {} if doi.blank?

      conn = faraday_conn('json', options)
      params = { q: "doi:" + doi,
                 rows: 1,
                 fl: "doi,creator,title,publisher,publicationYear,resourceTypeGeneral,description,datacentre,datacentre_symbol,prefix,relatedIdentifier,xml,updated",
                 wt: "json" }
      url = "http://search.datacite.org/api?" + URI.encode_www_form(params)

      response = conn.get url, {}, options[:headers]

      if is_json?(response.body)
        json = JSON.parse(response.body)

        metadata = json.fetch("response", {}).fetch("docs", []).first

        return { error: 'Resource not found.', status: 404 } if metadata.blank?

        doi = metadata.fetch("doi", nil)
        doi = doi.upcase if doi.present?
        title = metadata.fetch("title", []).first
        title = title.chomp(".") if title.present?

        xml = Base64.decode64(metadata.fetch('xml', "PGhzaD48L2hzaD4=\n"))
        xml = Hash.from_xml(xml).fetch("resource", {})
        authors = xml.fetch("creators", {}).fetch("creator", [])
        authors = [authors] if authors.is_a?(Hash)

        { "author" => get_hashed_authors(authors),
          "title" => title,
          "container-title" => metadata.fetch("publisher", nil),
          "description" => metadata.fetch("description", nil),
          "issued" => get_date_parts_from_parts(metadata.fetch("publicationYear", nil)),
          "DOI" => doi,
          "type" => metadata.fetch("resourceTypeGeneral", nil),
          "subtype" => metadata.fetch("resourceType", nil) }
      else
        { error: 'Resource not found.', status: 404 }
      end
    rescue *NETWORKABLE_EXCEPTIONS => e
      rescue_faraday_error(url, e, options)
    end

    def get_orcid_metadata(orcid, options = {})
      return {} if orcid.blank?

      conn = faraday_conn('json', options)
      url = "http://pub.orcid.org/v1.2/#{orcid}/orcid-bio"
      response = conn.get url, {}, options[:headers]

      if is_json?(response.body)
        json = JSON.parse(response.body)

        metadata = json.fetch("orcid-profile", nil)

        return { error: 'Resource not found.', status: 404 } if metadata[:error]

        metadata.extend Hashie::Extensions::DeepFetch
        personal_details = metadata.deep_fetch("orcid-bio", "personal-details") { {} }
        personal_details.extend Hashie::Extensions::DeepFetch
        author = { "family" => personal_details.deep_fetch("family-name", "value") { nil },
                   "given" => personal_details.deep_fetch("given-names", "value") { nil } }
        url = metadata.deep_fetch("orcid-identifier", "uri") { nil }
        timestamp = Time.zone.now.utc.iso8601

        { "author" => [author],
          "title" => "ORCID record for #{author.fetch('given', '')} #{author.fetch('family', '')}",
          "container-title" => "ORCID Registry",
          "issued" => get_date_parts(timestamp),
          "timestamp" => timestamp,
          "URL" => url,
          "type" => 'entry' }
      else
        { error: 'Resource not found.', status: 404 }
      end
    rescue *NETWORKABLE_EXCEPTIONS => e
      rescue_faraday_error(url, e, options)
    end

    def get_doi_ra(doi, options = {})
      return {} if doi.blank?

      conn = faraday_conn('json', options)
      url = "http://doi.crossref.org/doiRA/" + CGI.unescape(doi)
      response = conn.get url, {}, options[:headers]

      if is_json?(response.body)
        json = JSON.parse(response.body)
        ra = json.first.fetch("RA", nil)
        if ra.present?
          ra.delete(' ').downcase
        else
          error = json.first.fetch("status", "An error occured")
          { error: error, status: 400 }
        end
      else
        { error: 'Resource not found.', status: 404 }
      end
    rescue *NETWORKABLE_EXCEPTIONS => e
      rescue_faraday_error(url, e, options)
    end
  end
end
