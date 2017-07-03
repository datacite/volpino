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

    collection = collection.query(params[:query]) if params[:query]

    # check whether a list of dois has been claimed
    collection = collection.where(doi: params[:dois].split(',')) if params[:dois]

    page = params[:page] || { number: 1, size: 1000 }
    @claims = collection.order_by_date.page(page[:number]).per_page(page[:size])
    meta = { total: @claims.total_entries, 'total-pages' => @claims.total_pages , page: page[:number].to_i }
    render(json: @claims, meta: meta)
  end

  def create
    @claim = Claim.where(orcid: params.fetch(:claim, {}).fetch(:orcid, nil),
                         doi: params.fetch(:claim, {}).fetch(:doi, nil))
                  .first_or_initialize

    claim_action = params.dig(:claim, :claim_action) || "create"

    if @claim.new_record? ||
      @claim.source_id == "orcid_search" ||
      (claim_action == "create" && [2,4,5,6].include?(@claim.state)) ||
      (claim_action == "delete" && [2,3,4,6].include?(@claim.state))

      @claim.assign_attributes(state: 0,
                               source_id: params.dig(:claim, :source_id),
                               claim_action: claim_action)

      authorize! :create, @claim

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

  private

  def safe_params
    params.require(:claim).permit(:uuid, :orcid, :doi, :source_id, :claim_action)
  end
end
