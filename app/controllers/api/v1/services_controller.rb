class Api::V1::ServicesController < Api::BaseController
  before_filter :authenticate_user_from_token!

  # swagger_controller :services, "Services"
  #
  # swagger_api :show do
  #   summary "Show a service"
  #   param :path, :id, :string, :required, "Service name"
  #   response :ok
  #   response :unprocessable_entity
  #   response :not_found
  #   response :internal_server_error
  # end

  def index
    @services = Service.all.order('name')
    render json: @services, meta: { total: @services.size }
  end

  def show
    @service = Service.where(name: params[:id])
    render json: @service
  end
end
