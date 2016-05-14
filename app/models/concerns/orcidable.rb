module Orcidable
  extend ActiveSupport::Concern

  included do
    def oauth_client
      OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                         ENV['ORCID_CLIENT_SECRET'],
                         site: ENV['ORCID_API_URL'])
    end

    def application_token
      @application_token ||= oauth_client.client_credentials.get_token(scope: "/read-public")
    end

    def user_token
      OAuth2::AccessToken.new(oauth_client, authentication_token)
    end

    def oauth_client_get(options={})
      options[:endpoint] ||= "orcid-works"
      response = application_token.get "#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{uid}/#{options[:endpoint]}" do |request|
        request.headers['Accept'] = 'application/json'
      end

      return { "data" => JSON.parse(response.body) } if response.status == 200

      { "errors" => [{ "title" => "Error fetching ORCID record" }] }
    rescue OAuth2::Error => e
      { "errors" => [{ "title" => e.message }] }
    end

    def oauth_client_post(data, options={})
      options[:endpoint] ||= "orcid-works"
      response = user_token.post("#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{uid}/#{options[:endpoint]}") do |request|
        request.headers['Content-Type'] = 'application/orcid+xml'
        request.body = data
      end

      return { "data" => Hash.from_xml(data) } if response.status == 201

      { "errors" => [{ "title" => "Error depositing claim" }] }
    rescue OAuth2::Error => e
      { "errors" => [{ "title" => e.message }] }
    end

    def root_attributes
      { :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.2.xsd',
        :'xmlns' => 'http://www.orcid.org/ns/orcid' }
    end

    def schema
      Nokogiri::XML::Schema(open(ORCID_SCHEMA))
    end

    def validation_errors
      @validation_errors ||= schema.validate(Nokogiri::XML(data)).map { |error| error.to_s }
    end
  end
end
