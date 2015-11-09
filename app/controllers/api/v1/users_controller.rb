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
    page = params[:page] || 1
    @users = User.all.ordered.paginate(page: page, per_page: 1000)
    meta = { total: @users.total_entries, 'total-pages' => @users.total_pages , page: page }
    render json: @users, meta: meta
  end
end
