class Admin::ClaimsController < ApplicationController
  before_action :load_user, only: [:index, :update]
  before_action :load_claim, only: [:update]
  load_and_authorize_resource

  def index
    load_index
  end

  def update
    if params[:claim][:resolve]
      params[:claim][:state] = "waiting"
      params[:claim][:error_messages] = nil
      params[:claim] = params[:claim].except(:resolve)
    end

    @claim.update_attributes(safe_params)

    load_index

    render :index
  end

  protected

  def load_index
    if !@user.is_admin_or_staff?
      collection = @user.claims
    elsif params[:user_id]
      collection = Claim.where(orcid: params[:user_id])
      @claim_count = collection.count
      @my_claim_count = Claim.where(orcid: current_user.uid).count
    else
      collection = Claim
      @my_claim_count = Claim.where(orcid: current_user.uid).count
    end
    collection = collection.query(params[:query]) if params[:query]
    if params[:source].present?
      collection = collection.where(source_id: params[:source])
      @source = collection.group(:source_id).count.first
    end
    if params[:claim_action].present?
      collection = collection.where(claim_action: params[:claim_action])
      @claim_action = collection.group(:claim_action).count.first
    end
    if params[:state].present?
      collection = collection.where(aasm_state: params[:state])
      @state = collection.group(:aasm_state).count.first
    end
    @sources = collection.where.not(source_id: nil).group(:source_id).count
    @claim_actions = collection.where.not(claim_action: nil).group(:claim_action).count
    @states = collection.where.not(aasm_state: nil).group(:aasm_state).count
    @claims = collection.order_by_date.page(params[:page])
    @page = params[:page] || 1
  end

  def load_user
    if user_signed_in?
      @user = current_user
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  def load_claim
    @claim = Claim.where(uuid: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @claim.present?
  end

  private

  def safe_params
    params.require(:claim).permit(:state,
                                  :claim_action,
                                  :error_messages)
  end
end
