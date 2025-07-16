# frozen_string_literal: true

require "faraday"
require "json"

module Users
  class OrcidController < ApplicationController
    BASE_URL = "#{ENV["ORCID_URL"]}/oauth"
    CLIENT_ID = ENV["ORCID_SEARCH_AND_LINK_CLIENT_ID"]
    CLIENT_SECRET = ENV["ORCID_SEARCH_AND_LINK_CLIENT_SECRET"]

    before_action :load_user

    def search_and_link_auth
      response_type = "code"
      scope = "/authenticate"
      redirect_uri = ENV["ORCID_SEARCH_AND_LINK_REDIRECT_URI"]

      auth_url = "#{BASE_URL}/authorize?client_id=#{CLIENT_ID}&response_type=#{response_type}&scope=#{scope}&redirect_uri=#{redirect_uri}"

      redirect_to auth_url
    end

    def search_and_link_callback
      conn = Faraday.new(BASE_URL + "/token")

      body = {
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        grant_type: "authorization_code",
        code: params[:code],
      }

      response = conn.post do |req|
        req.headers["Accept"] = "application/json"
        req.body = body
      end

      if response.success?
        tokens = JSON.parse(response.body)
        expires_at = Time.now.utc + tokens["expires_in"].seconds

        @user.update(orcid_search_and_link_access_token: tokens["access_token"],
                     orcid_search_and_link_refresh_token: tokens["refresh_token"],
                     orcid_search_and_link_expires_at: expires_at)
      else
        puts "Error exchanging code for tokens: #{response.status} - #{response.body}"
        nil
      end

      redirect_to stored_location_for(:user) || setting_path("me")
    end

    def search_and_link_refresh
      conn = Faraday.new(BASE_URL + "/token")

      body = {
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        refresh_token: @user.orcid_search_and_link_refresh_token,
        grant_type: "refresh_token",
        code: params[:code],
      }

      response = conn.post do |req|
        req.body = body
      end

      if response.success?
        tokens = JSON.parse(response.body)
        expires_at = Time.now.utc + tokens["expires_in"].seconds

        @user.update(orcid_search_and_link_access_token: tokens["access_token"],
                     orcid_search_and_link_refresh_token: tokens["refresh_token"],
                     orcid_search_and_link_expires_at: expires_at)
      else
        puts "Error refreshing tokens: #{response.status} - #{response.body}"
        nil
      end

      redirect_to stored_location_for(:user) || setting_path("me")
    end

    def search_and_link_revoke
      conn = Faraday.new(BASE_URL + "/revoke")

      body = {
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        token: @user.orcid_search_and_link_access_token,
      }

      response = conn.post do |req|
        req.body = body
      end

      if response.success?
        @user.update(orcid_search_and_link_access_token: nil,
                     orcid_search_and_link_refresh_token: nil,
                     orcid_search_and_link_expires_at: nil)
      else
        puts "Error revoking tokens: #{response.status} - #{response.body}"
        nil
      end

      redirect_to stored_location_for(:user) || setting_path("me")
    end


    def load_user
      if user_signed_in?
        @user = current_user
      else
        fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
      end
    end
  end
end
