class Api::V1::MembersController < Api::BaseController
  swagger_controller :members, "Members"

  swagger_api :index do
    summary "Returns member information"
    param :query, 'page[number]', :integer, :optional, "Page number"
    param :query, 'page[size]', :integer, :optional, "Page size"
    response :ok
    response :unprocessable_entity
    response :not_found
  end

  swagger_api :show do
    summary "Show a member"
    param :path, :id, :string, :required, "Member name"
    response :ok
    response :unprocessable_entity
    response :not_found
    response :internal_server_error
  end

  def index
    page = params[:page] || { number: 1, size: 1000 }
    @members = Member.all.order('name').page(page[:number]).per_page(page[:size])
    meta = { total: @members.total_entries, 'total-pages' => @members.total_pages , page: page[:number].to_i }
    render json: @members, meta: meta
  end

  def show
    @member = Member.where(name: params[:id])
    render json: @member
  end
end
