class Api::V1::ClaimsController < Api::BaseController
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource

  swagger_controller :claims, "Claims"

  swagger_api :show do
    summary "Show a claim"
    param :path, :id, :string, :required, "claim ID"
    response :ok
    response :unprocessable_entity
    response :not_found
    response :internal_server_error
  end

  def show
    @claim = Claim.where(uuid: params[:id])
    render json: @claim
  end

  def index
    page = params[:page] || { number: 1, size: 1000 }
    @claims = Claim.all.order_by_date.page(page[:number]).per_page(page[:size])
    meta = { total: @claims.total_entries, 'total-pages' => @claims.total_pages , page: page[:number].to_i }
    render json: @claims, meta: meta
  end
end
