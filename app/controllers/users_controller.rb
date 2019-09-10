class UsersController < ApplicationController
  before_action :load_user, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource except: [:index]

  def show
    @title = 'Settings'
    render :show
  end

  def index
    load_index
  end

  def edit
    if @user == current_user
      # user updates his account
      render :edit
    else
      # admin updates user account
      load_index
      render :index
    end
  end

  def update
    if @user == current_user
      # user updates his account
      @user.update_attributes(safe_params)

      # delete GitHub external identifier from ORCID if GitHub account is unlinked
      GithubJob.perform_later(@user) if @user.github_uid.blank? && @user.github_put_code.present?

      render :show
    else
      # admin updates user account
      @user.update_attributes(safe_params)

      load_index
      render :index
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    load_index
    render :index
  end

  protected

  def load_user
    if user_signed_in? && params[:id] == "me"
      @user = current_user
    elsif user_signed_in?
      @user = User.find(params[:id])
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  def load_index
    authorize! :manage, Phrase

    collection = User

    if params['role-id']
      collection = collection.where(:role_id => params['role-id'])
      @role = User.where(role_id: params['role-id']).group(:role_id).count.first
    end

    if params['beta-tester']
      collection = collection.where(:beta_tester => true)
      @group = User.where(:beta_tester => true)
    end

    collection = collection.query(params[:query]) if params[:query]
    collection = collection.ordered

    @roles = User.where.not(role_id: nil).group(:role_id).count
    @groups = User.where(:beta_tester => true)
    @users = collection.page(params[:page])
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
