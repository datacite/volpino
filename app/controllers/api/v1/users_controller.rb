class Api::V1::UsersController < Api::BaseController
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource

  swagger_controller :users, "Users"

  swagger_api :show do
    summary "Show a user"
    param :path, :id, :string, :required, "me"
    response :ok
    response :unprocessable_entity
    response :not_found
    response :internal_server_error
  end

  def show
    @user = current_user
    render json: @user
  end

  def index
    page = params[:page] || { number: 1, size: 1000 }
    @users = User.all.ordered.page(page[:number]).per_page(page[:size])
    meta = { total: @users.total_entries, 'total-pages' => @users.total_pages , page: page[:number].to_i }
    render json: @users, meta: meta
  end
end
