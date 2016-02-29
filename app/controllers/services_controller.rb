class ServicesController < ApplicationController
  before_filter :load_service, only: [:show, :edit, :update, :destroy]
  before_filter :load_index, only: [:index]
  before_filter :new_service, only: [:create]
  before_action :authenticate_user!, :only => [:show]
  before_filter :load_user, only: [:show]
  load_and_authorize_resource :except => [:show]

  def show
    # use optional :origin and :q parameters to redirect to specific page
    url = @service.redirect_uri + '?'
    origin = params[:q].present? ? "/?q=#{params[:q]}" : params[:origin]

    redirect_to url +  URI.encode_www_form({
      jwt: @user.jwt_payload,
      origin: origin }.compact)
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
    @tags = @service.tags.all
    fail ActiveRecord::RecordNotFound unless @service.present?
  end

  def load_index
    collection = Service
    if params[:tag]
      collection = collection.joins(:tags).where('tags.name = ?', params[:tag])
      @tag = Tag.where(name: params[:tag]).first
    else
      @tag = nil
    end
    collection = collection.query(params[:query]) if params[:query]

    @services = collection.order(:title).paginate(:page => params[:page])
    @tags = Tag.joins(:services).distinct.order(:title)
  end

  def load_user
    if user_signed_in?
      @user = current_user
    else
      store_location_for(:user, services_path(params[:id]))
    end
  end

  private

  def safe_params
    params.require(:service).permit(:title, :name, :logo, :summary, :description, :url, :redirect_uri, :member_id, :tag_ids => [])
  end
end
