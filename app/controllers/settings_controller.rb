class SettingsController < ApplicationController
  before_action :load_user

  def show
    render :show
  end

  def edit
    render :show
  end

  def update
    @user.update_attributes(safe_params)
    
    # refresh cookie if ORCID token was deleted
    if safe_params[:orcid_token].blank? && safe_params[:orcid_expires_at].present?
      cookies[:_datacite] = encode_cookie(@user.jwt) 
      flash[:notice] = "ORCID token successfully deleted."
    end

    render :show
  end

  protected

  def load_user
    if user_signed_in?
      @user = current_user
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  private

  def safe_params
    params.require(:user).permit(:name,
                                 :email,
                                 :auto_update,
                                 :role_id,
                                 :is_public,
                                 :beta_tester,
                                 :provider_id,
                                 :client_id,
                                 :expires_at,
                                 :orcid_token,
                                 :orcid_expires_at,
                                 :github,
                                 :github_uid,
                                 :github_token,
                                 :authentication_token)
  end
end