class Users::SessionsController < Devise::SessionsController
  #prepend_before_action :authenticate_user!, :only => [:destroy]

  # GET /sign_in
  def new
    store_location_for(:user, request.referer)
    @show_image = true
    super
  end

  # POST /sign_in
  def create
    super
  end

  # GET /sign_out
  def destroy
    cookies[:_datacite] = empty_cookie
    super
  end

  def link_orcid
    if current_user.present?
      flash[:warning] = "You are already signed in."
      redirect_to root_path
    end

    @show_image = true
    flash.keep(:omniauth)
  end

  def empty_cookie
    value = '{"authenticated":{}}'
    
    domain = if Rails.env.production?
               ".datacite.org"
             elsif Rails.env.stage?
               ".test.datacite.org"
             else
               nil
             end
    
    # URI.encode optional parameter needed to encode colon
    { value: value, #URI.encode(value, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
      expires: 30.days.from_now.utc,
      secure: !Rails.env.development? && !Rails.env.test?,
      domain: domain }
  end
end
