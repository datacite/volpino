class Api::V1::DepositsController < Api::BaseController
  prepend_before_filter :load_deposit, only: [:show, :destroy]
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource :except => [:create]

  swagger_controller :deposits, "Deposits"

  swagger_api :index do
    summary 'Returns all deposits, sorted by date'
    param :query, :message_type, :string, :optional, "Filter by message_type"
    param :query, :source_token, :string, :optional, "Filter by source_token"
    param :query, :state, :string, :optional, "Filter by state"
    response :ok
    response :unprocessable_entity
    response :not_found
  end

  swagger_api :show do
    summary 'Returns deposit by ID'
    param :path, :id, :string, :required, "Deposit ID"
    response :ok
    response :unprocessable_entity
    response :not_found
  end

  def create
    @deposit = Deposit.new(safe_params)
    authorize! :create, @deposit

    if @deposit.save
      render json: @deposit, :status => :accepted
    else
      render json: { errors: @deposit.errors.map { |error| { status: 400, title: error } }}, status: :bad_request
    end
  end

  def show
    render json: @deposit
  end

  def index
    collection = Deposit.all

    collection = collection.where(message_type: params[:message_type]) if params[:message_type]
    collection = collection.where(source_token: params[:source_token]) if params[:source_token]
    if params[:state]
      states = { "waiting" => 0, "working" => 1, "failed" => 2, "done" => 3 }
      state = states.fetch(params[:state], 0)
      collection = collection.where(state: state)
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 1000
    @deposits = collection.order("created_at DESC").paginate(:page => page[:number])
    meta = { total: @deposits.total_entries, 'total-pages' => @deposits.total_pages , page: page[:number] }
    render json: @deposits, meta: meta
  end

  def destroy
    if @deposit.destroy
      render json: { deposit: {} }, meta: { status: "deleted" }, status: :ok
    else
      render json: { errors: [{ status: 400, title: "An error occured." }] }, status: :bad_request
    end
  end

  protected

  def load_deposit
    @deposit = Deposit.where(uuid: params[:id]).first

    fail ActiveRecord::RecordNotFound unless @deposit.present?
  end

  private

  def safe_params
    # extra = params.fetch(:deposit, {}).fetch(:events, {}).fetch(:extra, {}).fetch(:keys, [])
    # works = [:pid, :DOI, :author, :"container-title", :title, :publisher_id, :registration_agency, :tracked, :type, :contributors, related_works: [:pid, :source_id, :relation_type_id], issued: { "date-parts" => [] }]
    # events = [:source_id, :work_id, :pdf, :html, :readers, :comments, :likes, :total, extra: extra]
    # contributors = [:pid, :source_id, :author, :"container-title", :title, :issued, :publisher_id, :registration_agency, :tracked, :type]
    # publishers = [:name, :title, :other_names, :prefixes, :registration_agency, :active]
    # params.require(:deposit).permit(:uuid, :message_type, :source_token, :callback, message: { works: works, events: events, contributors: contributors, publishers: publishers })

    # whitelisting all parameters as we can't control what is deposited
    params.require(:deposit).permit!
  end
end
