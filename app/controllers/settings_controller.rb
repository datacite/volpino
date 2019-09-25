class SettingsController < ApplicationController
  before_action :load_user
  load_and_authorize_resource

  def index
    @title = 'Settings'
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
end