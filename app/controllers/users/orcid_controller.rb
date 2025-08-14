# frozen_string_literal: true

require "faraday"
require "json"

module Users
  class OrcidController < ApplicationController
    BASE_URL = "#{ENV["ORCID_URL"]}/oauth"
    SCOPES_AUTO_UPDATE = ["/activities/update", "/read-limited"].freeze
    SCOPES_SEARCH_AND_LINK = ["/activities/update", "/read-limited"].freeze

    before_action :load_user, only: [:auto_update_refresh, :auto_update_revoke, :search_and_link_refresh, :search_and_link_revoke]

    # Auto-update methods
    def auto_update_auth
      auth_url = build_auth_url(ENV["ORCID_AUTO_UPDATE_CLIENT_ID"],
                                ENV["ORCID_AUTO_UPDATE_REDIRECT_URI"],
                                SCOPES_AUTO_UPDATE.join(" "))

      redirect_to auth_url
    end


    def auto_update_callback
      response = callback(ENV["ORCID_AUTO_UPDATE_CLIENT_ID"],
                        ENV["ORCID_AUTO_UPDATE_CLIENT_SECRET"],
                        params[:code])

      @user = User.from_orcid(response[:id])

      @user.update(orcid_auto_update_access_token: response[:access_token],
                   orcid_auto_update_refresh_token: response[:refresh_token],
                   orcid_auto_update_expires_at: response[:expires_at])

      redirect_to stored_location_for(:user) || setting_path("me")
    end


    def auto_update_refresh
      response = refresh(ENV["ORCID_AUTO_UPDATE_CLIENT_ID"],
                       ENV["ORCID_AUTO_UPDATE_CLIENT_SECRET"],
                       @user.orcid_auto_update_refresh_token)

      @user.update(orcid_auto_update_access_token: response[:access_token],
                   orcid_auto_update_refresh_token: response[:refresh_token],
                   orcid_auto_update_expires_at: response[:expires_at])

      redirect_to stored_location_for(:user) || setting_path("me")
    end


    def auto_update_revoke
      revoke(ENV["ORCID_AUTO_UPDATE_CLIENT_ID"],
             ENV["ORCID_AUTO_UPDATE_CLIENT_SECRET"],
             @user.orcid_auto_update_access_token)

      @user.update(orcid_auto_update_access_token: nil,
                   orcid_auto_update_refresh_token: nil,
                   orcid_auto_update_expires_at: nil)

      redirect_to stored_location_for(:user) || setting_path("me")
    end


    # Search and Link methods
    def search_and_link_auth
      auth_url = build_auth_url(ENV["ORCID_SEARCH_AND_LINK_CLIENT_ID"],
                                ENV["ORCID_SEARCH_AND_LINK_REDIRECT_URI"] + "?redirect_to_commons=false",
                                SCOPES_SEARCH_AND_LINK.join(" "))

      redirect_to auth_url
    end


    def search_and_link_callback
      response = callback(ENV["ORCID_SEARCH_AND_LINK_CLIENT_ID"],
                        ENV["ORCID_SEARCH_AND_LINK_CLIENT_SECRET"],
                        params[:code])


      @user = User.from_orcid(response[:id])
      sign_in @user

      @user.update(orcid_search_and_link_access_token: response[:access_token],
                   orcid_search_and_link_refresh_token: response[:refresh_token],
                   orcid_search_and_link_expires_at: response[:expires_at])

      # Redirect to Commons if the flag isn't explicitly false. Otherwise redirect to profile settings
      if params["redirect_to_commons"] != "false"
        redirect_to "#{ENV['COMMONS_URL']}/orcid.org/#{@user.orcid}"
      else
        redirect_to stored_location_for(:user) || setting_path("me")
      end
    end


    def search_and_link_refresh
      response = refresh(ENV["ORCID_SEARCH_AND_LINK_CLIENT_ID"],
                       ENV["ORCID_SEARCH_AND_LINK_CLIENT_SECRET"],
                       @user.orcid_search_and_link_refresh_token)

      @user.update(orcid_search_and_link_access_token: response[:access_token],
                   orcid_search_and_link_refresh_token: response[:refresh_token],
                   orcid_search_and_link_expires_at: response[:expires_at])

      redirect_to stored_location_for(:user) || setting_path("me")
    end


    def search_and_link_revoke
      revoke(ENV["ORCID_SEARCH_AND_LINK_CLIENT_ID"],
             ENV["ORCID_SEARCH_AND_LINK_CLIENT_SECRET"],
             @user.orcid_search_and_link_access_token)

      @user.update(orcid_search_and_link_access_token: nil,
                   orcid_search_and_link_refresh_token: nil,
                   orcid_search_and_link_expires_at: nil)

      redirect_to stored_location_for(:user) || setting_path("me")
    end


    def load_user
      if user_signed_in?
        @user = current_user
      else
        fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
      end
    end

    private
      def build_auth_url(client_id, redirect_uri, scope)
        response_type = "code"
        "#{BASE_URL}/authorize?client_id=#{client_id}&response_type=#{response_type}&scope=#{scope}&redirect_uri=#{redirect_uri}"
      end


      def callback(client_id, client_secret, code)
        conn = Faraday.new(BASE_URL + "/token")

        body = {
          client_id: client_id,
          client_secret: client_secret,
          grant_type: "authorization_code",
          code: code,
        }

        response = conn.post do |req|
          req.headers["Accept"] = "application/json"
          req.body = body
        end

        unless response.success?
          raise "Error exchanging code for tokens: #{response.status} - #{response.body}"
        end

        parse_body(response.body)
      end


      def refresh(client_id, client_secret, refresh_token)
        conn = Faraday.new(BASE_URL + "/token")

        body = {
          client_id: client_id,
          client_secret: client_secret,
          refresh_token: refresh_token,
          grant_type: "refresh_token",
        }

        response = conn.post do |req|
          req.body = body
        end

        unless response.success?
          raise "Error refreshing tokens: #{response.status} - #{response.body}"
        end

        parse_body(response.body)
      end


      def revoke(client_id, client_secret, access_token)
        conn = Faraday.new(BASE_URL + "/revoke")

        body = {
          client_id: client_id,
          client_secret: client_secret,
          token: access_token,
        }

        response = conn.post do |req|
          req.body = body
        end

        unless response.success?
          raise "Error revoking tokens: #{response.status} - #{response.body}"
        end
      end


      def parse_body(json)
        body = JSON.parse(json)
        expires_at = Time.now.utc + body["expires_in"].seconds

        {
          id: body["orcid"],
          access_token: body["access_token"],
          refresh_token: body["refresh_token"],
          expires_at: expires_at
        }
      end
  end
end
