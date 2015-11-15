class Api::V1::UsersController < Api::BaseController
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource

  swagger_controller :users, "Users"

  swagger_api :show do
    summary "Show a user"
    param :path, :id, :string, :required, "me"
    param :query, 'recent', :integer, :optional, "Limit to profiles created last x days"
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
    page = params[:page]
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 1000

    collection = User
    collection = collection.last_x_days(params[:recent].to_i) if params[:recent]
    @users = collection.ordered.page(page[:number]).per_page(page[:size])

    meta = { total: @users.total_entries, 'total-pages' => @users.total_pages, page: page[:number].to_i }
    render json: @users, meta: meta
  end
end
