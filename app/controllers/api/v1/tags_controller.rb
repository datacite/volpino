class Api::V1::TagsController < Api::BaseController

  swagger_controller :tags, "Tags"

  swagger_api :index do
    summary "Returns tags information"
    param :query, :query, :string, :optional, "Query for tags"
    param :query, 'page[number]', :integer, :optional, "Page number"
    param :query, 'page[size]', :integer, :optional, "Page size"
    response :ok
    response :unprocessable_entity
    response :not_found
  end

  swagger_api :show do
    summary "Show a tag"
    param :path, :id, :string, :required, "Tag name"
    response :ok
    response :unprocessable_entity
    response :not_found
    response :internal_server_error
  end

  def index
    page = params[:page] || { number: 1, size: 1000 }
    collection = Tag
    collection = collection.query(params[:query]) if params[:query]
    @tags = collection.order(:title).page(page[:number]).per_page(page[:size])

    meta = { total: @tags.total_entries, 'total-pages' => @tags.total_pages , page: page[:number].to_i }
    render json: @tags, meta: meta
  end

  def show
    @tag = Tag.where(name: params[:id]).first
    render json: @tag
  end
end
