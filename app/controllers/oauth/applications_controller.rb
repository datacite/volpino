class Oauth::ApplicationsController < ApplicationController
  before_filter :load_application, only: [:show, :edit, :update, :destroy]
  before_filter :new_application, only: [:create]
  load_and_authorize_resource class: 'Doorkeeper::Application'

  def show
    respond_to do |format|
      format.js { render :show }
      format.html
    end
  end

  def index
    load_index
  end

  def new
    @application = Doorkeeper::Application.new
    load_index
    render :index
  end

  def create
    @application.save
    load_index
    render :index
  end

  def edit
    load_index
    render :index
  end

  def update
    @application.update_attributes(safe_params)
    load_index
    render :index
  end

  def destroy
    @application.destroy
    load_index
    render :index
  end

  protected

  def new_application
    @application = Doorkeeper::Application.new(safe_params)
    @application.owner = current_user if Doorkeeper.configuration.confirm_application_owner?
  end

  def load_application
    @application = Doorkeeper::Application.where(id: params[:id]).first
  end

  def load_index
    if current_user.is_admin? && params[:user_id].blank?
      collection = Doorkeeper::Application
    else
      collection = current_user.applications
    end
    collection = collection.where('name like ?', params[:query]) if params[:query]
    @applications = collection.paginate(:page => params[:page])
    @title = 'Applications'
  end

  private

  def safe_params
    params.require(:doorkeeper_application).permit(:name,
                                                   :redirect_uri,
                                                   :scopes)
  end
end
