class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  rescue_from ActiveRecord::RecordInvalid do |exception|
    redirect_to root_path, :alert => exception.message
  end

  def failure
    flash[:alert] = "Error signing in with ORCID: #{request.env["omniauth.error.type"].to_s.humanize}"
    redirect_to root_path
  end

  # generic handler for all omniauth providers
  def action_missing(provider)
    auth = request.env["omniauth.auth"]

    @user = User.from_omniauth(auth)
    unless @user.skip_info
      @user.update_attributes(family_name: auth.info.fetch(:last_name, nil),
                              given_names: auth.info.fetch(:first_name, nil),
                              other_names: auth.extra.fetch(:raw_info, {}).fetch(:other_names, nil),
                              skip_info: true)
    end

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]
      flash[:alert] = @user.errors.map { |k,v| "#{k}: #{v}" }.join("<br />").html_safe || "Error signing in with #{provider}"
      redirect_to root_path
    end
  end
end
