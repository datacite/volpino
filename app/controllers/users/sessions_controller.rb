class Users::SessionsController < Devise::SessionsController
  #prepend_before_action :authenticate_user!, :only => [:destroy]

  # GET /sign_in
  def new
    @show_image = true
    super
  end

  # POST /sign_in
  def create
    super
  end

  # DELETE /sign_out
  def destroy
    @service = Service.where(name: params[:id]).first
    url = @service.present? ? @service.url : nil
    sign_out current_user
    flash[:notice] = "Signed out successfully." if url.nil?
    redirect_to url || root_path
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
