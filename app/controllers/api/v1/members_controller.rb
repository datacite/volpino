class Api::V1::MembersController < Api::BaseController
  def index
    collection = Member
    collection = collection.query(params[:query]) if params[:query]

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
      member_types = [{ id: params[:member_type],
                        title: params[:member_type],
                        count: collection.where(member_type: params[:member_type]).count }]
    else
      member_types = collection.where.not(member_type: nil).group(:member_type).count
      member_types = member_types.map { |k,v| { id: k, title: k.humanize, count: v } }
    end
    if params[:region].present?
      regions = [{ id: params[:region],
                   title: params[:region],
                   count: collection.where(region: params[:region]).count }]
    else
      regions = collection.where.not(region: nil).group(:region).count
      regions = regions.map { |k,v| { id: k.downcase, title: REGIONS[k], count: v } }
    end
    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where(year: params[:year]).count }]
    else
      years = collection.where.not(year: nil).order("year DESC").group(:year).count
      years = years.map { |k,v| { id: k, title: k, count: v } }
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
    fail ActiveRecord::RecordNotFound unless @member.present?

    render json: @member
  end
end
