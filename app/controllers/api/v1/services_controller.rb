class Api::V1::ServicesController < Api::BaseController

  swagger_controller :services, "Services"

  swagger_api :index do
    summary "Returns service information"
    param :query, :query, :string, :optional, "Query for services"
    param :query, 'page[number]', :integer, :optional, "Page number"
    param :query, 'page[size]', :integer, :optional, "Page size"
    response :ok
    response :unprocessable_entity
    response :not_found
  end

  swagger_api :show do
    summary "Show a service"
    param :path, :id, :string, :required, "Service name"
    response :ok
    response :unprocessable_entity
    response :not_found
    response :internal_server_error
  end

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
    render json: @service
  end
end
