class Api::V1::UsersController < Api::BaseController
  before_filter :authenticate_user_from_token!

  # swagger_controller :users, "Users"
  #
  # swagger_api :show do
  #   summary "Show a user"
  #   param :path, :id, :string, :required, "me"
  #   response :ok
  #   response :unprocessable_entity
  #   response :not_found
  #   response :internal_server_error
  # end

  def show
    @user = current_user
    render json: @user
  end

  def index
    @users = User.all.order('family_name, given_names').paginate(page: params[:page], per_page: 1000)
    render json: @users, meta: { total: @users.size }
  end
end
