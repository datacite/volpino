class UsersController < ApplicationController
  before_filter :load_user, only: [:show, :edit, :destroy]
  load_and_authorize_resource

  def show
    @title = 'Settings'
    respond_to do |format|
      format.js { render @panel }
      format.html
    end
  end

  def index
    load_index
  end

  def edit
    if params[:panel].present?
      # user updates his account
      render @panel
    else
      # admin updates user account
      @user = User.find(params[:id])
      load_index
      render :index
    end
  end

  def update
    if params[:panel].present?
      # user updates his account

      load_user

      @user.update_attributes(safe_params)

      render @panel
    else
      # admin updates user account
      @user = User.find(params[:id])
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
    if user_signed_in?
      @user = current_user
      @member = @user.member

      panels = %w(account login auto)
      @panel = panels.find { |p| p == params[:panel] } || "auto"
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  def load_index
    collection = User
    if params[:role]
      collection = collection.where(:role => params[:role])
      @role = User.where(role: params[:role]).group(:role).count.first
    end
    collection = collection.query(params[:query]) if params[:query]
    collection = collection.ordered

    @roles = User.group(:role).count
    @users = collection.paginate(:page => params[:page])
  end

  private

  def safe_params
    params.require(:user).permit(:name,
                                 :email,
                                 :unconfirmed_email,
                                 :auto_update,
                                 :role,
                                 :member_id,
                                 :expires_at,
                                 :facebook_uid,
                                 :facebook_token,
                                 :google_uid,
                                 :google_token,
                                 :github,
                                 :github_uid,
                                 :github_token,
                                 :api_key,
                                 :authentication_token)
  end
end
