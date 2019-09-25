class SettingsController < ApplicationController
  before_action :load_user

  def show
    render :show
  end

  def edit
    render :show
  end

  def update
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
end