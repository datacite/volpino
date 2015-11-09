class Api::BaseController < ActionController::Base
  # include base controller methods
  include Authenticable

  serialization_scope :view_context

  before_filter :default_format_json,
                :authenticate_user_from_token!,
                :cors_preflight_check
  after_filter :cors_set_access_control_headers, :set_jsonp_format

  protected

  def is_admin_or_staff?
    current_user && current_user.is_admin_or_staff? ? 1 : 0
  end
end
