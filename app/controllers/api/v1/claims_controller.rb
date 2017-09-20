class Api::V1::ClaimsController < Api::BaseController
  prepend_before_filter :load_claim, only: [:show, :destroy]
  prepend_before_filter :load_user, only: [:index]
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource :except => [:create]

  def show
    @claim = Claim.where(uuid: params[:id]).first
    render json: @claim
  end

  def index
    if @user
      collection = @user.claims
    else
      collection = Claim
    end

    if params[:query]
      collection = collection.query(params[:query])
    elsif params[:dois]
      # check whether a list of dois has been claimed
      collection = collection.where(doi: params[:dois].split(','))
    end

    collection = collection.where(orcid: params[:user_id]) if params[:user_id].present?
    collection = collection.where(source_id: params[:source_id]) if params[:source_id].present?
    collection = collection.where(claim_action: params[:claim_action]) if params[:claim_action].present?
    collection = collection.where(status: params[:status]) if params[:status].present?

    if @user
      users = [{ id: @user.orcid,
                 title: @user.orcid,
                 count: collection.count }]
    elsif params[:user_id].present?
      users = [{ id: params[:user_id],
                 title: params[:user_id],
                 count: collection.where(orcid: params[:user_id]).count }]
    else
      users = nil
    end

    if params[:source_id].present?
      sources = [{ id: params[:source_id],
                   title: human_source_name(params[:source_id]),
                   count: collection.where(source_id: params[:source_id]).count }]
    else
      sources = collection.where.not(source_id: nil).group(:source_id).count
      sources = sources.map { |k,v| { id: k.to_s, title: human_source_name(k), count: v } }
    end

    if params[:claim_action].present?
      claim_actions = [{ id: params[:claim_action],
                         title: params[:claim_action].humanize,
                         count: collection.where(claim_action: params[:claim_action]).count }]
    else
      claim_actions = collection.where.not(claim_action: nil).group(:claim_action).count
      claim_actions = claim_actions.map { |k,v| { id: k.to_s, title: k.humanize, count: v } }
    end

    if params[:state].present?
      states = [{ id: human_state_name(params[:state]),
                  title: human_state_name(params[:state]).humanize,
                  count: collection.where(state: params[:state]).count }]
    else
      states = collection.where.not(state: nil).group(:state).count
      states = states.map { |k,v| { id: human_state_name(k), title: human_state_name(k).humanize, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 1000

    @claims = collection.order_by_date.page(page[:number]).per_page(page[:size])

    meta = { total: @claims.total_entries,
             total_pages: @claims.total_pages ,
             page: page[:number].to_i,
             users: users,
             sources: sources,
             claim_actions: claim_actions,
             states: states }.compact

    render json: @claims, meta: meta
  end

  def create
    @claim = Claim.where(orcid: params.fetch(:claim, {}).fetch(:orcid, nil),
                         doi: params.fetch(:claim, {}).fetch(:doi, nil))
                  .first_or_initialize

    authorize! :create, @claim

    claim_action = params.dig(:claim, :claim_action) || "create"

    if @claim.new_record? ||
      @claim.source_id == "orcid_search" ||
      (claim_action == "create" && [2,4,5,6].include?(@claim.state)) ||
      (claim_action == "delete" && [2,3,4,6].include?(@claim.state))

      @claim.assign_attributes(state: 0,
                               source_id: params.fetch(:claim, {}).fetch(:source_id, nil),
                               claim_action: claim_action)

      if @claim.save
        render json: @claim, :status => :accepted
      else
        render json: { errors: @claim.errors.to_a.map { |error| { status: 400, title: error } }}, status: :bad_request
      end
    else
      render json: @claim, :status => :accepted
    end
  rescue ActiveRecord::RecordNotUnique
    render json: @claim, :status => :ok
  end

  def destroy
    if @claim.destroy
      render json: { data: {} }, meta: { status: "deleted" }, status: :ok
    else
      render json: { errors: [{ status: 400, title: "An error occured." }] }, status: :bad_request
    end
  end

  protected

  def load_claim
    @claim = Claim.where(uuid: params[:id]).first

    fail ActiveRecord::RecordNotFound unless @claim.present?
  end

  def load_user
    return nil unless params[:user_id].present?

    @user = User.where(uid: params[:user_id]).first

    fail ActiveRecord::RecordNotFound unless @user.present?
  end

  def human_source_name(source_id)
    sources.fetch(source_id, nil)
  end

  def sources
    { "orcid_search" => "ORCID Search and Link",
      "orcid_update" => "ORCID Auto-Update" }
  end

  def human_state_name(state)
    state_names.fetch(state, nil)
  end

  def state_names
    { 0 => "waiting",
      1 => "working",
      2 => "failed",
      3 => "done",
      4 => "ignored",
      5 => "deleted",
      6 => "notified" }
  end

  private

  def safe_params
    params.require(:claim).permit(:uuid, :orcid, :doi, :source_id, :claim_action)
  end
end
