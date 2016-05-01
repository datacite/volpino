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

    @user = current_user
    @user.update_attributes(github: auth.info.nickname,
                            github_uid: auth.uid,
                            github_token: auth.credentials.token)

    flash[:notice] = "Account successfully linked with GitHub account."
    redirect_to user_path("me")
  end

  # generic handler for all omniauth providers
  def action_missing(provider)
    auth = request.env["omniauth.auth"]

    @user = User.from_omniauth(auth)
    if Time.zone.now > @user.expires_at
      auth_hash = User.get_auth_hash(auth)
      @user.update_attributes(auth_hash)
    end

    if @user.persisted?
      sign_in @user
      redirect_to stored_location_for(:user) || root_path
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]
      flash[:alert] = @user.errors.map { |k,v| "#{k}: #{v}" }.join("<br />").html_safe || "Error signing in with #{provider}"
      redirect_to root_path
    end
  end
end
