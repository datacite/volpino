class WorksController < ApplicationController
  before_filter :load_user
  load_and_authorize_resource

  def index
    @page = params[:page] || 1
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
