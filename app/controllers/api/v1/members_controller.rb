class Api::V1::MembersController < Api::BaseController
  before_filter :load_member, only: [:show, :update, :destroy]
  before_filter :new_member, only: [:create]
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  def index
    collection = Member

    if params[:id].present?
      collection = collection.where(name: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    collection = collection.where(member_type: params[:member_type]) if params[:member_type].present?
    collection = collection.where(region: params[:region]) if params[:region].present?
    collection = collection.where(year: params[:year]) if params[:year].present?

    # calculate facet counts after filtering
    if params["member-type"].present?
      member_types = [{ id: params["member-type"],
                        title: params["member-type"].humanize,
                        count: collection.where(member_type: params["member-type"]).count }]
    else
      member_types = collection.where.not(member_type: nil).group(:member_type).count
      member_types = member_types.map { |k,v| { id: k, title: k.humanize, count: v } }
    end
    if params[:region].present?
      regions = [{ id: params[:region],
                   title: REGIONS[params[:region].upcase],
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
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 1000

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

  protected

  def new_member
    @member = Member.new(safe_params)
  end

  def load_member
    @member = Member.where(name: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @member.present?
  end

  private

  def safe_params
    params.fetch(:member, {}).permit(:title, :name, :description, :member_type, :country_code, :website, :year, :email, :phone, :logo, :image, :image_cache)
  end
end
