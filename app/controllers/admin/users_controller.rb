class Admin::UsersController < ApplicationController
  # include base controller methods
  include Authenticable

  before_action :load_user, only: [:edit, :update, :destroy]
  load_and_authorize_resource except: [:index]

  def index
    load_index

    render :index
  end

  def edit
    load_index

    render :edit
  end

  def update
    # if @user == current_user
    #   # user updates his account
    #   @user.update_attributes(safe_params)

    #   # refresh cookie if ORCID token was deleted
    #   if safe_params[:orcid_token].blank? && safe_params[:orcid_expires_at].present?
    #     cookies[:_datacite] = encode_cookie(@user.jwt) 
    #     flash[:notice] = "ORCID token successfully deleted."
    #   end

    #   # delete GitHub external identifier from ORCID if GitHub account is unlinked
    #   GithubJob.perform_later(@user) if @user.github_uid.blank? && @user.github_put_code.present?

    #   render :show
    # else

    # admin updates user account
    @user.update_attributes(safe_params)

    load_index
    render :edit
  end

  def destroy
    @user.destroy
    load_index
    render :index
  end

  protected

  def load_user
    if user_signed_in?
      @user = User.where(uid: params[:id]).first
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  def load_index
    authorize! :manage, Phrase

    collection = User

    if params['role-id']
      collection = collection.where(role_id: params['role-id'])
      @role = User.where(role_id: params['role-id']).group(:role_id).count.first
    end

    if params['beta-tester']
      collection = collection.where(beta_tester: true)
      @group = User.where(beta_tester: true)
    end

    collection = collection.query(params[:query]) if params[:query]

    @roles = collection.where.not(role_id: nil).group(:role_id).count
    @groups = collection.where(:beta_tester => true)
    @users = collection.ordered.page(params[:page])
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
