class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :devise_current_user

  def after_sign_in_path_for(resource)
    stored_location_for(:user) || user_path("me")
  end

  def after_sign_out_path_for(resource_or_scope)
    request.referrer || root_path
  end

  #convert parameters with hyphen to parameters with underscore.
  # https://stackoverflow.com/questions/35812277/fields-parameters-with-hyphen-in-ruby-on-rails
  def transform_params
    params.transform_keys! { |key| key.tr('-', '_') }
  end

  def authenticate_user!
    if user_signed_in?
      super
    else
      redirect_to "/sign_in"
    end
  end

  # override devise method as user may come from different subsite
  def store_location_for(resource_or_scope, location)
    session_key = stored_location_key_for(resource_or_scope)
    session[session_key] = location
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end
end
