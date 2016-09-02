class ServicesController < ApplicationController
  prepend_before_action :authenticate_user!, :only => [:show]

  before_action :store_location, :only => [:show]
  before_action :load_service, only: [:show, :edit, :update, :destroy]
  before_action :load_index, only: [:index]
  before_action :new_service, only: [:create]

  load_and_authorize_resource :except => [:show]

  def show
    # use optional :query parameter to redirect to specific page
    url = @service.url
    url += "/works?query=#{params[:query]}" if params[:query]

    redirect_to url
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

    if @service.present?
      @tags = @service.tags.all
    else
      redirect_to root_url
    end
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

  def store_location
    store_location_for(:user, service_path(params[:id]))
  end

  private

  def safe_params
    params.require(:service).permit(:title, :name, :logo, :summary, :description, :url, :redirect_uri, :member_id, :image, :image_cache, :tag_ids => [])
  end
end
