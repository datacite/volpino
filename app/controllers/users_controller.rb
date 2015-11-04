class UsersController < ApplicationController
  before_filter :load_user, only: [:show, :edit, :destroy]
  load_and_authorize_resource

  def show
    @title = 'Settings'
    respond_to do |format|
      format.js { render :show }
      format.html
    end
  end

  def index
    load_index
  end

  def edit
    if params[:id].to_i == current_user.id
      # user updates his account
      render :show
    else
      # admin updates user account
      @user = User.find(params[:id])
      load_index
      render :index
    end
  end

  def update
    if params[:id].to_i == current_user.id
      # user updates his account

      load_user

      sign_in @user, :bypass => true if @user.update_attributes(safe_params)

      render :show
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
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  def load_index
    collection = User
    if params[:role]
      collection = collection.where(:role => params[:role])
      @role = params[:role]
    end
    collection = collection.query(params[:query]) if params[:query]
    collection = collection.ordered

    @users = collection.paginate(:page => params[:page])
  end

  private

  def safe_params
    params.require(:user).permit(:name,
                                 :email,
                                 :auto_update,
                                 :role,
                                 :authentication_token)
  end
end
