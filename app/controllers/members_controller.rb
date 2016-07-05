class MembersController < ApplicationController
  before_filter :load_member, only: [:show, :edit, :update, :destroy]
  before_filter :load_index, only: [:index]
  before_filter :new_member, only: [:create]
  before_action :authenticate_user!
  load_and_authorize_resource

  def index
  end

  def show

  end

  def new
    @member = Member.new
    load_index
    render :index
  end

  def create
    @member.save

    load_index
    render :index
  end

  def edit
    render :show
  end

  def update
    @member.update_attributes(safe_params)
    render :show
  end

  def destroy
    @member.destroy
    redirect_to members_path
  end

  protected

  def new_member
    @member = Member.new(safe_params)
  end

  def load_member
    @member = Member.where(name: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @member.present?
  end

  def load_index
    collection = Member
    if params[:id].present?
      collection = collection.where(name: params[:id])
    end
    if params[:member_type].present?
      collection = collection.where(member_type: params[:member_type])
      @member_type = Member.where(member_type: params[:member_type]).group(:member_type).count.first
    end
    if params[:region].present?
      collection = collection.where(region: params[:region])
      @region = Member.where(region: params[:region]).group(:region).count.first
    end
    if params[:year].present?
      collection = collection.where(year: params[:year])
      @year = Member.where(year: params[:year]).group(:year).count.first
    end

    collection = collection.query(params[:query]) if params[:query]

    @member_types = collection.where.not(member_type: nil).group(:member_type).count
    @regions = collection.where.not(region: nil).group(:region).count
    @years = collection.where.not(year: nil).group(:year).count
    @members = collection.order(:title).paginate(:page => params[:page])
  end

  private

  def safe_params
    params.require(:member).permit(:title, :name, :description, :member_type, :country_code, :website, :year, :email, :phone, :logo)
  end
end
