# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
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

  def github
    auth = request.env["omniauth.auth"]

    if current_user.present?
      @user = current_user
      @user.update(github: auth.info.nickname,
                   github_uid: auth.uid,
                   github_token: auth.credentials.token)

      flash[:notice] = "Account successfully linked with GitHub account."

      if stored_location_for(:user) == ENV["BLOG_URL"] + "/admin/"
        if @user.role_id == "staff_admin"
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
    elsif @user = User.where(github_uid: auth.uid).first
      cookies[:_datacite] = encode_cookie(@user.jwt)

      sign_in @user

      if stored_location_for(:user) == ENV["BLOG_URL"] + "/admin/"
        if @user.role_id == "staff_admin"
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
      flash[:omniauth] = { "github" => auth.info.nickname,
                           "github_uid" => auth.uid,
                           "github_token" => auth.credentials.token }
      redirect_to "/link_orcid"
    end
  end

  def globus
    auth = request.env["omniauth.auth"]

    if current_user.present?
      @user = current_user
      @user.update(email: auth.info.email, organization: auth.extra.id_info? ? auth.extra.id_info.organization : nil)
      flash[:notice] = "Account successfully linked with Globus account."
      redirect_to user_path("me") && return
    else
      # extract ORCID ID from preferred_username
      @user = User.from_omniauth(auth, provider: "globus", uid: auth.extra.id_info.preferred_username[0..18])
    end

    if Time.zone.now > @user.expires_at
      auth_hash = User.get_auth_hash(auth, authentication_token: auth.credentials.token, expires_at: Time.at(auth.credentials.expires_at).utc)
      @user.update(auth_hash)
    end

    if @user.persisted?
      sign_in @user

      cookies[:_datacite] = encode_cookie(@user.jwt)

      redirect_to stored_location_for(:user) || setting_path("me")
    else
      flash[:alert] = @user.errors.map { |k, v| "#{k}: #{v}" }.join("<br />").html_safe || "Error signing in with #{provider}"
      redirect_to root_path
    end
  end

  def orcid
    auth = request.env["omniauth.auth"]
    omniauth = flash[:omniauth] || {}

    if current_user.present?
      @user = current_user
      @user.update(orcid_expires_at: User.timestamp(auth.credentials),
                   orcid_token: auth.credentials.token)
      flash[:notice] = "ORCID token successfully refreshed."
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

  def netlify_response(token: nil, content: nil)
    content = { token: token, provider: "github" } if token.present?
    content ||= "Error authenticating user."

    message = "success" if token.present?
    message ||= "error"

    @post_message = "authorization:github:#{message}:#{content.to_json}".to_json
    render "users/sessions/netlify", layout: false, status: :ok
  end
end
