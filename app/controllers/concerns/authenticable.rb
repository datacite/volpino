module Authenticable
  extend ActiveSupport::Concern

  included do
    def default_format_json
      request.format = :json if request.format.html?
    end

    def authenticate_user_from_token!
      authenticate_with_http_token do |token, options|
        unless token.present?
          current_user = false
          return false
        end

        public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
        jwt = (JWT.decode token, public_key, true, { :algorithm => 'RS256' }).first
        user = token && User.where(uid: jwt[:uid]).first

        if user && Devise.secure_compare(user.uid, jwt[:uid])
          sign_in user, store: false
        else
          current_user = false
        end
      end
    end

    rescue_from *RESCUABLE_EXCEPTIONS do |exception|
      status = case exception.class.to_s
               when "CanCan::AccessDenied" then 401
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
end
