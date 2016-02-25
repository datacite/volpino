class TagsController < ApplicationController
  before_filter :load_tag, only: [:edit, :update, :destroy]
  before_filter :load_index, only: [:index]
  before_filter :new_tag, only: [:create]
  load_and_authorize_resource

  def index
  end

  def new
    @tag = Tag.new
    load_index
    render :index
  end

  def create
    @tag.save

    load_index
    render :index
  end

  def edit
    load_index
    render :index
  end

  def update
    @tag.update_attributes(safe_params)
    load_index
    render :index
  end

  def destroy
    @tag.destroy
    load_index
    render :index
  end

  protected

  def new_tag
    @tag = Tag.new(safe_params)
  end

  def load_tag
    @tag = Tag.where(name: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @tag.present?
  end

  def load_index
    collection = Tag
    if params[:service]
      collection = collection.joins(:services).where('services.name = ?', params[:service])
      @service = Service.where(name: params[:service]).first
    else
      @service = nil
    end
    collection = collection.query(params[:query]) if params[:query]

    @tags = collection.order(:title).paginate(:page => params[:page])
    @services = Service.joins(:tags).distinct.order(:title)
  end

  private

  def safe_params
    params.require(:tag).permit(:title, :name, :service_ids => [])
  end
end
