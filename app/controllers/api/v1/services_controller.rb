class Api::V1::ServicesController < Api::BaseController
  before_filter :authenticate_user_from_token!

  swagger_controller :services, "Services"

  swagger_api :index do
    summary "Returns service information"
    param :query, :page, :integer, :optional, "Page number"
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
    page = params[:page] || 1
    @services = Service.all.order('name').paginate(page: page, per_page: 1000)
    meta = { total: @services.total_entries, 'total-pages' => @services.total_pages , page: page }
    render json: @services, meta: meta
  end

  def show
    @service = Service.where(name: params[:id])
    render json: @service
  end
end
