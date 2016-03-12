class ClaimsController < ApplicationController
  before_filter :load_user
  load_and_authorize_resource

  def index
    if !@user.is_admin_or_staff?
      collection = @user.claims
    elsif params[:user_id]
      collection = Claim.where(orcid: @user.uid)
      @my_claim_count = collection.count
    else
      collection = Claim
      @my_claim_count = Claim.where(orcid: @user.uid).count
    end
    collection = collection.query(params[:query]) if params[:query]
    if params[:source].present?
      collection = collection.where(source_id: params[:source])
      @source = collection.group(:source_id).count.first
    end
    if params[:state].present?
      collection = collection.where(state: params[:state])
      @state = collection.group(:state).count.first
    end
    @sources = collection.where.not(source_id: nil).group(:source_id).count
    @states = collection.where.not(state: nil).group(:state).count
    @claims = collection.order_by_date.paginate(:page => params[:page])
    @page = params[:page] || 1
  end

  protected

  def load_user
    if user_signed_in?
      @user = current_user
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end
end
