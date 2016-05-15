class Users::SessionsController < Devise::SessionsController
  #prepend_before_action :authenticate_user!, :only => [:destroy]

  # GET /sign_in
  def new
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
end
