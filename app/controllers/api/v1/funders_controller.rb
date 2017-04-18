class Api::V1::FundersController < Api::BaseController
  def index
    collection = Funder
    collection = collection.query(params[:query]) if params[:query]

    if params[:id].present?
      collection = collection.where(name: params[:id])
    end
    if params[:fundref_id].present?
      collection = collection.where(fundref_id: params[:fundref_id])
      @fundref_id = collection.where(fundref_id: params[:fundref_id]).group(:fundref_id).count.first
    end
    if params[:name].present?
      collection = collection.where(name: params[:name])
      @name = collection.where(name: params[:name]).group(:name).count.first
    end

    page = params[:page] || { number: 1, size: 1000 }

    @funders = collection.order(:fundref_id).page(page[:name]).per_page(page[:size])

    meta = { total: @funders.total_entries,
             total_pages: @funders.total_pages ,
             page: page[:number].to_i
            }
    render json: @funders, meta: meta
  end

  def show
    @funders = Funder.where(name: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @funders.present?

    render json: @funders
  end
end
