# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    rescue_from ActiveRecord::RecordInvalid do |exception|
      redirect_to root_path, alert: exception.message
    end

    # include base controller methods
    include Authenticable

    def forward
      store_location_for(:user, request.referer)

      if params[:provider].present?
        redirect_post("/users/auth/#{params[:provider]}", options: { authenticity_token: :auto })
      else
        flash[:alert] = "Error signing in: no provider"
        redirect_to root_path
      end
    end

    def failure
      flash[:alert] = "Error signing in: #{request.env['omniauth.error.type'].to_s.humanize}"
      redirect_to root_path
    end

    def orcid
      auth = request.env["omniauth.auth"]
      omniauth = flash[:omniauth] || {}

      if current_user.present?
        @user = current_user
      else
        @user = User.from_omniauth(auth, provider: "globus")
      end

      if Time.zone.now > @user.expires_at || omniauth.present?
        auth_hash = User.get_auth_hash(auth, omniauth)
        @user.update(auth_hash)

        # push GitHub external identifier to ORCID if GitHub account is linked
        GithubJob.perform_later(@user) if @user.github_put_code.blank? && @user.github.present?
      end

      if @user.persisted?
        sign_in @user

        cookies[:_datacite] = encode_cookie(@user.jwt)

        if stored_location_for(:user) == ENV["BLOG_URL"] + "/admin/"
          if @user.github_token.blank?
            token = nil
            content = "No GitHub token found."
          elsif @user.role_id == "staff_admin"
            token = @user.github_token
            content = nil
          else
            token = nil
            content = "No permission."
          end

          netlify_response(token: token, content: content)
        else
          redirect_to stored_location_for(:user) || setting_path("me")
        end
      else
        flash[:alert] = @user.errors.map { |k, v| "#{k}: #{v}" }.join("<br />").html_safe || "Error signing in with #{provider}"
        redirect_to root_path
      end
    end
  end
end
