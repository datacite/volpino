class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] || stored_location_for(resource) || '/users/me'
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
      format.html do
        if /(jpe?g|png|gif|css)/i == request.path
          render text: message, status: status
        else
          @message = message
          @status = status
          render "notifications/show", status: status
        end
      end
      format.xml { render xml: { error: message }.to_xml, status: status }
      format.rss { render :show, status: status, layout: false }
      format.all { render json: { meta: { status: "error", error: message }}, status: status }
    end
  end
end
