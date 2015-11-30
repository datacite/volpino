module Clientable
  extend ActiveSupport::Concern

  included do
    require 'oauth2'

    def access_token
      client = OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                                  ENV['ORCID_CLIENT_SECRET'],
                                  site: 'http://api.orcid.org')
      OAuth2::AccessToken.new(client, authentication_token)
    end

    def oauth_client_get
      access_token.get "http://api.orcid.org/v#{ORCID_VERSION}/#{uid}/orcid-works" do |get|
        get.headers['Accept'] = 'application/json'
      end
    end

    def oauth_client_post(data)
      access_token.post("http://api.orcid.org/v#{ORCID_VERSION}/#{uid}/orcid-works") do |post|
        post.headers['Content-Type'] = 'application/orcid+xml'
        post.body = data
      end
    end
  end
end
