class Api::V1::UsersController < Api::BaseController
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource

  swagger_controller :users, "Users"

  swagger_api :show do
    summary "Show a user"
    param :path, :id, :string, :required, "me"
    param :query, 'from-created-date', :integer, :optional, "Created on or after specified date in ISO 8601 format"
    param :query, 'until-created-date', :integer, :optional, "Created not later than specified date in ISO 8601 format"
    param :query, 'page[number]', :integer, :optional, "Page number"
    param :query, 'page[size]', :integer, :optional, "Results per page (1-1000), defaults to 1000"
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
    from_date = params['from-created-date'].presence || '2015-11-01'
    until_date = params['until-created-date'].presence || Time.zone.now.to_date.iso8601
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 1000

    collection = User.where(created_at: from_date..until_date)
    @users = collection.ordered.page(page[:number]).per_page(page[:size])

    meta = { total: @users.total_entries, 'total-pages' => @users.total_pages, page: page[:number].to_i }
    render json: @users, meta: meta
  end
end
