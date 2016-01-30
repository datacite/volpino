module Authenticable
  extend ActiveSupport::Concern

  included do
    def default_format_json
      request.format = :json if request.format.html?
    end

    # from https://github.com/spree/spree/blob/master/api/app/controllers/spree/api/base_controller.rb
    def set_jsonp_format
      if params[:callback] && request.get?
        self.response_body = "#{params[:callback]}(#{response.body})"
        headers["Content-Type"] = 'application/javascript'
      end
    end

    # looking for header "Authorization: Token token=12345"
    def authenticate_user_from_token!
      authenticate_with_http_token do |token, options|
        user = token && User.where(api_key: token).first

        if user && Devise.secure_compare(user.api_key, token)
          sign_in user, store: false
        else
          current_user = false
        end
      end
    end

    def cors_set_access_control_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Max-Age'] = "1728000"
    end

    def cors_preflight_check
      if request.method == :options
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
        headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
        headers['Access-Control-Max-Age'] = '1728000'
        render :text => '', :content_type => 'text/plain'
      end
    end

    rescue_from *RESCUABLE_EXCEPTIONS do |exception|
      status = case exception.class.to_s
               when "CanCan::AccessDenied" then 401
               when "ActiveRecord::RecordNotFound" then 404
               when "ActiveModel::ForbiddenAttributesError", "NoMethodError" then 422
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
end
