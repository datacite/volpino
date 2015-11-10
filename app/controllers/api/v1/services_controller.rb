class Api::V1::ServicesController < Api::BaseController
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource

  swagger_controller :services, "Services"

  swagger_api :index do
    summary "Returns service information"
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
    @services = Service.all.order('name').page(page[:number]).per_page(page[:size])
    meta = { total: @services.total_entries, 'total-pages' => @services.total_pages , page: page[:number].to_i }
    render json: @services, meta: meta
  end

  def show
    @service = Service.where(name: params[:id])
    render json: @service
  end
end
