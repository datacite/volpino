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

  # DELETE /sign_out
  def destroy
    cookies.delete :_datacite_jwt, domain: :all
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
end
