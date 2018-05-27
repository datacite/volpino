class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  rescue_from ActiveRecord::RecordInvalid do |exception|
    redirect_to root_path, :alert => exception.message
  end

  def forward
    store_location_for(:user, request.referer)
  
    if params[:provider].present?
      redirect_to "/users/auth/#{params[:provider]}" 
    else
      flash[:alert] = "Error signing in: no provider"
      redirect_to root_path
    end
  end

  def failure
    flash[:alert] = "Error signing in: #{request.env["omniauth.error.type"].to_s.humanize}"
    redirect_to root_path
  end

  def github
    auth = request.env["omniauth.auth"]

    if current_user.present?
      @user = current_user
      @user.update_attributes(github: auth.info.nickname,
                              github_uid: auth.uid,
                              github_token: auth.credentials.token)

      flash[:notice] = "Account successfully linked with GitHub account."

      if stored_location_for(:user) == ENV['BLOG_URL'] + "/admin/"
        if @user.role_id == "staff_admin"
          token = @user.github_token
          content = nil
        else
          token = nil
          content = "No permission."
        end

        netlify_response(token: token, content: content)
      else
        redirect_to stored_location_for(:user) || user_path("me", panel: "login")
      end
    elsif @user = User.where(github_uid: auth.uid).first
      cookies[:_datacite_jwt] = { value: @user.jwt,
                                  expires: 14.days.from_now.utc,
                                  secure: !Rails.env.development? && !Rails.env.test?,
                                  domain: :all }
      sign_in @user

      if stored_location_for(:user) == ENV['BLOG_URL'] + "/admin/"
        if @user.role_id == "staff_admin"
          token = @user.github_token
          content = nil
        else
          token = nil
          content = "No permission."
        end

        netlify_response(token: token, content: content)
      else
        redirect_to stored_location_for(:user) || user_path("me")
      end
    else
      flash[:omniauth] = { "github" => auth.info.nickname,
                           "github_uid" => auth.uid,
                           "github_token" => auth.credentials.token }
      redirect_to "/link_orcid"
    end
  end

  def google_oauth2
    auth = request.env["omniauth.auth"]

    if current_user.present?
      @user = current_user
      @user.update_attributes(google_uid: auth.uid,
                              google_token: auth.credentials.token,
                              email: auth.info.email)
      flash[:notice] = "Account successfully linked with Google account."
      redirect_to user_path("me", panel: "login")
    elsif @user = User.where(google_uid: auth.uid).first
      cookies[:_datacite_jwt] = { value: @user.jwt,
                                 expires: 14.days.from_now.utc,
                                 secure: !Rails.env.development? && !Rails.env.test?,
                                 domain: :all }
      sign_in @user
      redirect_to stored_location_for(:user) || user_path("me")
    else
      flash[:omniauth] = { "google_uid" => auth.uid,
                           "google_token" => auth.credentials.token,
                           "email" => auth.info.email }
      redirect_to "/link_orcid"
    end
  end

  def orcid
    auth = request.env["omniauth.auth"]
    omniauth = flash[:omniauth] || {}

    if current_user.present?
      @user = current_user
      @user.update_attributes(expires_at: User.timestamp(auth.credentials),
                              authentication_token: auth.credentials.token)
      flash[:notice] = "ORCID token successfully refreshed."
    else
      @user = User.from_omniauth(auth)
    end

    if Time.zone.now > @user.expires_at || omniauth.present?
      auth_hash = User.get_auth_hash(auth, omniauth)
      @user.update_attributes(auth_hash)

      # push GitHub external identifier to ORCID if GitHub account is linked
      GithubJob.perform_later(@user) if @user.github_put_code.blank? && @user.github.present?
    end

    if @user.persisted?
      sign_in @user
      cookies[:_datacite_jwt] = { value: @user.jwt,
                                 expires: 14.days.from_now.utc,
                                 secure: !Rails.env.development? && !Rails.env.test?,
                                 domain: :all }

      if stored_location_for(:user) == ENV['BLOG_URL'] + "/admin/"
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
        redirect_to stored_location_for(:user) || user_path("me", panel: "orcid")
      end
    else
      flash[:alert] = @user.errors.map { |k,v| "#{k}: #{v}" }.join("<br />").html_safe || "Error signing in with #{provider}"
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
