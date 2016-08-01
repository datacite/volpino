class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  rescue_from ActiveRecord::RecordInvalid do |exception|
    redirect_to root_path, :alert => exception.message
  end

  def failure
    flash[:alert] = "Error signing in with ORCID: #{request.env["omniauth.error.type"].to_s.humanize}"
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
    elsif @user = User.where(github_uid: auth.uid).first
      sign_in @user if @user
    end

    if @user.present?
      redirect_to stored_location_for(:user) || user_path("me")
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
    elsif @user = User.where(google_uid: auth.uid).first
      sign_in @user if @user
    end

    if @user.present?
      redirect_to stored_location_for(:user) || user_path("me")
    else
      flash[:omniauth] = { "google_uid" => auth.uid,
                           "google_token" => auth.credentials.token,
                           "email" => auth.info.email }
      redirect_to "/link_orcid"
    end
  end

  def facebook
    auth = request.env["omniauth.auth"]

    if current_user.present?
      @user = current_user
      @user.update_attributes(facebook_uid: auth.uid,
                              facebook_token: auth.credentials.token)
      flash[:notice] = "Account successfully linked with Facebook account."
    elsif @user = User.where(facebook_uid: auth.uid).first
      sign_in @user if @user
    end

    if @user.present?
      redirect_to stored_location_for(:user) || user_path("me")
    else
      flash[:omniauth] = { "facebook_uid" => auth.uid,
                           "facebook_token" => auth.credentials.token }
      redirect_to "/link_orcid"
    end
  end

  def orcid
    auth = request.env["omniauth.auth"]
    omniauth = flash[:omniauth] || {}

    if current_user.present?
      @user = current_user
      @user.update_attributes(expires_at: User.timestamp(auth.credentials))
      flash[:notice] = "ORCID token successfully refreshed."
    else
      @user = User.from_omniauth(auth)
    end

    if Time.zone.now > @user.expires_at || omniauth.present?
      auth_hash = User.get_auth_hash(auth, omniauth)
      @user.update_attributes(auth_hash)
    end

    if @user.persisted?
      sign_in @user
      redirect_to stored_location_for(:user) ||  user_path("me")
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]
      flash[:alert] = @user.errors.map { |k,v| "#{k}: #{v}" }.join("<br />").html_safe || "Error signing in with #{provider}"
      redirect_to root_path
    end
  end
end
