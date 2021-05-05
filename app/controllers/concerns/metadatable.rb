module Metadatable
  extend ActiveSupport::Concern

  module ClassMethods
    include Bolognese::Utils
    include Bolognese::DoiUtils

    def get_orcid_metadata(orcid)
      url = ENV["ORCID_API_URL"] + "/v#{ORCID_VERSION}/#{orcid}/person"
      response = Maremma.get(url, accept: "application/vnd.orcid+json", bearer: ENV["ORCID_TOKEN"])
      return {} if response.status != 200

      message = response.body.fetch("data", {})
      parse_message(message: message)
    end

    def parse_message(message: nil)
      uid = message.dig("orcid-identifier", "path")
      given_names = message.dig("name", "given-names", "value")
      family_name = message.dig("name", "family-name", "value")

      name = if message.dig("name", "credit-name", "value").present?
               message.dig("name", "credit-name", "value")
             elsif given_names.present? || family_name.present?
               [given_names, family_name].join(" ")
             else
               uid
             end

      {
        uid: uid,
        given_names: given_names,
        family_name: family_name,
        name: name,
      }.compact
    end
  end
end
