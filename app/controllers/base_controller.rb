class BaseController < ActionController::Base
  # include base controller methods
  include Authenticable

  # include helper module for sparse fieldsets
  include Fieldable

  # include helper module for pagination
  include Paginatable

  # include helper module for facets
  include Facetable

  # include helper module for formatting errors
  include ErrorSerializable

  attr_accessor :current_user

  # pass ability into serializer
  serialization_scope :current_ability

  before_action :default_format_json, :transform_params, :set_raven_context
  after_action :set_jsonp_format, :set_consumer_header

  # from https://github.com/spree/spree/blob/master/api/app/controllers/spree/api/base_controller.rb
  def set_jsonp_format
    if params[:callback] && request.get?
      self.response_body = "#{params[:callback]}(#{response.body})"
      headers["Content-Type"] = 'application/javascript'
    end
  end

  def set_consumer_header
    if current_user
      response.headers['X-Credential-Username'] = current_user.uid
    else
      response.headers['X-Anonymous-Consumer'] = true
    end
  end

  def default_format_json
    request.format = :json if request.format.html?
  end

  #convert parameters with hyphen to parameters with underscore.
  # https://stackoverflow.com/questions/35812277/fields-parameters-with-hyphen-in-ruby-on-rails
  def transform_params
    params.transform_keys! { |key| key.tr('-', '_') }
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
               when "CanCan::AuthorizationNotPerformed", "JWT::DecodeError" then 401
               when "CanCan::AccessDenied" then 403
               when "ActiveRecord::RecordNotFound", "AbstractController::ActionNotFound", "ActionController::RoutingError" then 404
               when "ActionController::UnknownFormat" then 406
               when "ActiveRecord::RecordNotUnique" then 409
               when "ActiveModel::ForbiddenAttributesError", "ActionController::ParameterMissing", "ActionController::UnpermittedParameters", "ActiveModelSerializers::Adapter::JsonApi::Deserialization::InvalidDocument" then 422
               when "SocketError" then 500 
               else 400
               end

      if status == 401
        message = "Bad credentials."
      elsif status == 403 && current_user.try(:uid)
        message = "You are not authorized to access this resource."
      elsif status == 403
        status = 401
        message = "Bad credentials."
      elsif status == 404
        message = "The resource you are looking for doesn't exist."
      elsif status == 406
        message = "The content type is not recognized."
      elsif status == 409
        message = "The resource already exists."
      elsif ["JSON::ParserError", "Nokogiri::XML::SyntaxError", "ActionDispatch::Http::Parameters::ParseError"].include?(exception.class.to_s)
        message = exception.message
      else
        Raven.capture_exception(exception)

        message = exception.message
      end

      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
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

  def set_raven_context
    if current_user.try(:uid)
      Raven.user_context(
        email: current_user.email,
        id: current_user.uid,
        ip_address: request.ip
      )
    else
      Raven.user_context(
        ip_address: request.ip
      ) 
    end
  end
end
