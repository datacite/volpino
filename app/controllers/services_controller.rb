class ServicesController < ApplicationController
  before_filter :load_service, only: [:show, :edit, :update, :destroy]
  before_filter :load_index, only: [:index]
  before_filter :new_service, only: [:create]
  before_filter :load_user, only: [:show]
  load_and_authorize_resource

  def show
    redirect_to "#{@service.redirect_uri}?jwt=#{@user.jwt_payload}"
  end

  def index
  end

  def new
    @service = Service.new
    load_index
    render :index
  end

  def create
    @service.save

    load_index
    render :index
  end

  def edit
    load_index
    render :index
  end

  def update
    @service.update_attributes(safe_params)
    load_index
    render :index
  end

  def destroy
    @service.destroy
    load_index
    render :index
  end

  protected

  def new_service
    @service = Service.new(safe_params)
  end

  def load_service
    @service = Service.where(name: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @service.present?
  end

  def load_index
    collection = Service
    collection = collection.query(params[:query]) if params[:query]

    @services = collection.order(:name).paginate(:page => params[:page])
  end

  def load_user
    if user_signed_in?
      @user = current_user
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  private

  def safe_params
    params.require(:service).permit(:title, :name, :redirect_uri)
  end
end