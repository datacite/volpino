class Api::V1::TagsController < Api::BaseController
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
    fail ActiveRecord::RecordNotFound unless @tag.present?

    render json: @tag
  end
end
