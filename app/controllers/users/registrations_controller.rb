class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters, if: :devise_controller?

  def new
    redirect_to new_user_session_path if User.count > 0
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:name, :family_name, :given_names, :email) }
  end

  def after_inactive_sign_up_path_for(_resource_or_scope)
    session["user_return_to"] || root_path
  end
end
