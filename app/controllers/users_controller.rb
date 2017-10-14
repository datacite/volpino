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

      # delete GitHub external identifier from ORCID if GitHub account is unlinked
      GithubJob.perform_later(@user) if @user.github_uid.blank? && @user.github_put_code.present?

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
      @member = Member.where(name: @user.provider_id).first if @user.provider_id.present? && %w(staff_admin provider_admin provider_user).include?(@user.role_id)
      @providers = Provider.all[:data]
      @sandboxes = Client.where("provider-id" => "SANDBOX")[:data]

      panels = %w(auto public login account orcid sandbox)
      @panel = panels.find { |p| p == params[:panel] } || "account"
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  def load_index
    collection = User

    if params['role-id']
      collection = collection.where(:role_id => params['role-id'])
      @role = User.where(role_id: params['role-id']).group(:role_id).count.first
    end

    collection = collection.query(params[:query]) if params[:query]
    collection = collection.ordered

    @providers = Provider.all[:data]
    @roles = User.group(:role_id).count
    @users = collection.paginate(:page => params[:page])
  end

  private

  def safe_params
    params.require(:user).permit(:name,
                                 :email,
                                 :unconfirmed_email,
                                 :auto_update,
                                 :role_id,
                                 :is_public,
                                 :provider_id,
                                 :client_id,
                                 :sandbox_id,
                                 :sandbox_name,
                                 :expires_at,
                                 :google_uid,
                                 :google_token,
                                 :github,
                                 :github_uid,
                                 :github_token,
                                 :authentication_token)
  end
end
