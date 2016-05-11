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
    collection = Member
    collection = collection.query(params[:q]) if params[:q]

    if params[:id].present?
      collection = collection.where(name: params[:id])
    end
    if params[:member_type].present?
      collection = collection.where(member_type: params[:member_type])
      @member_type = collection.where(member_type: params[:member_type]).group(:member_type).count.first
    end
    if params[:region].present?
      collection = collection.where(region: params[:region])
      @region = collection.where(region: params[:region]).group(:region).count.first
    end
    if params[:year].present?
      collection = collection.where(year: params[:year])
      @year = collection.where(year: params[:year]).group(:year).count.first
    end

    # calculate facet counts after filtering
    if params[:member_type].present?
      member_types = { params[:member_type] => collection.where(member_type: params[:member_type]).count }
    else
      member_types = collection.where.not(member_type: nil).group(:member_type).count
    end
    if params[:region].present?
      regions = { params[:region] => collection.where(region: params[:region]).count }
    else
      regions = collection.where.not(region: nil).group(:region).count
    end
    if params[:year].present?
      years = { params[:year] => collection.where(year: params[:year]).count }
    else
      years = collection.where.not(year: nil).order("year DESC").group(:year).count
    end

    page = params[:page] || { number: 1, size: 1000 }

    @members = collection.order(:title).page(page[:number]).per_page(page[:size])

    meta = { total: @members.total_entries,
             total_pages: @members.total_pages ,
             page: page[:number].to_i,
             member_types: member_types,
             regions: regions,
             years: years }
    render json: @members, meta: meta
  end

  def show
    @member = Member.where(name: params[:id]).first
    render json: @member
  end
end
