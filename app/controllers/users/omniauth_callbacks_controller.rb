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
      cookies[:_datacite] = encode_cookie(@user.jwt)
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

  def globus
    puts request.env["omniauth.auth"]
    auth = request.env["omniauth.auth"]

    if current_user.present?
      @user = current_user
      @user.update_attributes(email: auth.info.email)
      flash[:notice] = "Account successfully linked with Globus Auth account."
      redirect_to user_path("me")
    else
      @user = User.from_omniauth(auth, uid: auth.extra.id_info.preferred_username[0..18])
    end

    if Time.zone.now > @user.expires_at
      auth_hash = User.get_auth_hash(auth)
      @user.update_attributes(auth_hash)
    end

    if @user.persisted?
      sign_in @user
      cookies[:_datacite] = encode_cookie(@user.jwt)
      redirect_to stored_location_for(:user) || user_path("me")
    else
      flash[:alert] = @user.errors.map { |k,v| "#{k}: #{v}" }.join("<br />").html_safe || "Error signing in with #{provider}"
      redirect_to root_path
    end
  end

  def orcid
    auth = request.env["omniauth.auth"]
    omniauth = flash[:omniauth] || {}

    if current_user.present?
      @user = current_user
      @user.update_attributes(orcid_expires_at: User.timestamp(auth.credentials),
                              orcid_token: auth.credentials.token)
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
      cookies[:_datacite] = encode_cookie(@user.jwt)

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
        redirect_to stored_location_for(:user) || user_path("me")
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

  def encode_cookie(jwt)
    expires_in = 30 * 24 * 3600
    expires_at = Time.now.to_i + expires_in
    value = '{"authenticated":{"authenticator":"authenticator:oauth2","access_token":"' + jwt + '","expires_in":' + expires_in.to_s + ',"expires_at":' + expires_at.to_s + '}}'
    
    domain = if Rails.env.production?
               ".datacite.org"
             elsif Rails.env.stage?
               ".test.datacite.org"
             else
               ".lvh.me"
             end
    
    # URI.encode optional parameter needed to encode colon
    { value: URI.encode(value, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
      expires: 30.days.from_now.utc,
      secure: !Rails.env.development? && !Rails.env.test?,
      domain: domain }
  end
end
