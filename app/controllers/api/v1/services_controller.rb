class Api::V1::ServicesController < Api::BaseController
  def index
    page = params[:page] || { number: 1, size: 1000 }
    collection = Service
    collection = collection.joins(:tags).where('tags.name = ?', params[:tag]) if params[:tag]
    collection = collection.query(params[:query]) if params[:query]
    @services = collection.order(:title).page(page[:number]).per_page(page[:size])

    meta = { total: @services.total_entries, 'total-pages' => @services.total_pages , page: page[:number].to_i }
    render json: @services, meta: meta
  end

  def show
    @service = Service.where(name: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @service.present?

    render json: @service
  end
end
