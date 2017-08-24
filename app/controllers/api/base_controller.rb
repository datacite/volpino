class Api::BaseController < ActionController::Base
  # include base controller methods
  include Authenticable

  attr_accessor :current_user

  # pass ability into serializer
  serialization_scope :current_ability

  before_filter :default_format_json
  after_filter :set_jsonp_format

  # from https://github.com/spree/spree/blob/master/api/app/controllers/spree/api/base_controller.rb
  def set_jsonp_format
    if params[:callback] && request.get?
      self.response_body = "#{params[:callback]}(#{response.body})"
      headers["Content-Type"] = 'application/javascript'
    end
  end

  def default_format_json
    request.format = :json if request.format.html?
  end

  def authenticate_user_from_token!
    token = token_from_request_headers
    return false unless token.present?

    payload = decode_token(token)
    return false unless payload.present?

    # find user associated with token
    user = User.where(uid: payload["uid"]).first
    return false unless user && Devise.secure_compare(user.uid, payload["uid"])

    @current_user = user
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  # from https://github.com/nsarno/knock/blob/master/lib/knock/authenticable.rb
  def token_from_request_headers
    unless request.headers['Authorization'].nil?
      request.headers['Authorization'].split.last
    end
  end

  unless Rails.env.development?
    rescue_from *RESCUABLE_EXCEPTIONS do |exception|
      status = case exception.class.to_s
               when "CanCan::AccessDenied", "JWT::DecodeError" then 401
               when "ActiveRecord::RecordNotFound" then 404
               when "ActiveModel::ForbiddenAttributesError", "ActionController::UnpermittedParameters", "NoMethodError" then 422
               else 400
               end

      if status == 404
        message = "The page you are looking for doesn't exist."
      elsif status == 401
        message = "You are not authorized to access this page."
      else
        message = exception.message
      end

      respond_to do |format|
        format.all { render json: { errors: [{ status: status.to_s,
                                               title: message }]
                                  }, status: status
                   }
      end
    end
  end

  protected

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  # def is_admin?
  #   current_user && current_user.role == "staff_admin"
  # end
  #
  # def is_admin_or_staff?
  #   current_user && %w(staff_admin staff_user).include?(current_user.role)
  # end
end
