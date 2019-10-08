class Admin::ClaimsController < ApplicationController
  before_action :load_user, only: [:index, :edit, :update, :destroy]
  before_action :load_claim, only: [:edit, :update, :destroy]
  load_and_authorize_resource

  def index
    load_index
  end

  def edit
    load_index

    render :edit
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

  def destroy
    @claim.destroy
    load_index
    render :index
  end

  protected

  def load_index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "doi" then { "doi.raw" => { order: 'asc' }}
           when "-doi" then { "doi.raw" => { order: 'desc' }}
           when "orcid" then { orcid: { order: 'asc' }}
           when "-orcid" then { orcid: { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           when "updated" then { updated: { order: 'asc' }}
           when "-updated" then { updated: { order: 'desc' }}
           else { "updated" => { order: 'desc' }}
           end

    @page = params[:page] || 1
  
    response = Claim.query(params[:query],
                            dois: params[:dois],
                            user_id: params[:user_id],
                            source_id: params[:source_id],
                            claim_action: params[:claim_action],
                            state: params[:state],
                            created: params[:created],
                            claimed: params[:claimed],
                            page: { number: @page }, 
                            sort: sort)
  
    @total = response.results.total
    @claims = response.results

    @created = @total > 0 ? facet_by_year(response.response.aggregations.created.buckets) : nil
    @sources = @total > 0 ? facet_by_key(response.response.aggregations.sources.buckets) : nil
    @users = @total > 0 ? facet_by_id(response.response.aggregations.users.buckets) : nil
    @claim_actions = @total > 0 ? facet_by_key(response.response.aggregations.claim_actions.buckets) : nil
    @states = @total > 0 ? facet_by_key(response.response.aggregations.states.buckets) : nil
  end

  def load_user
    if user_signed_in?
      @user = current_user
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  def load_claim
    if user_signed_in?
      @claim = Claim.where(uuid: params[:id]).first
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, Claim)
    end
  end

  private

  def safe_params
    params.require(:claim).permit(:state,
                                  :aasm_state,
                                  :put_code,
                                  :claim_action,
                                  :error_messages)
  end
end
