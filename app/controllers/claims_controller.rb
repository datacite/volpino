# frozen_string_literal: true

class ClaimsController < BaseController
  # prepend_before_action :load_user, only: [:index]
  prepend_before_action :authenticate_user_from_token!
  before_action :load_claim, only: %i[show destroy]
  before_action :set_include, only: %i[index show create]
  load_and_authorize_resource except: [:create]

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: ClaimSerializer.new(@claim, options).serializable_hash.to_json, status: :ok
  end

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: "desc" } }
           when "doi" then { "doi" => { order: "asc" } }
           when "-doi" then { "doi" => { order: "desc" } }
           when "orcid" then { orcid: { order: "asc" } }
           when "-orcid" then { orcid: { order: "desc" } }
           when "created" then { created: { order: "asc" } }
           when "-created" then { created: { order: "desc" } }
           when "updated" then { updated: { order: "asc" } }
           when "-updated" then { updated: { order: "desc" } }
           else { "updated" => { order: "desc" } }
    end

    page = page_from_params(params)

    response = if params[:id].present?
      Claim.find_by(id: params[:id])
    elsif params[:ids].present?
      Claim.find_by_id(params[:ids], page: page, sort: sort)
    else
      Claim.query(params[:query],
                  dois: params[:dois],
                  user_id: params[:user_id],
                  source_id: params[:source_id],
                  claim_action: params[:claim_action],
                  state: params[:state],
                  created: params[:created],
                  claimed: params[:claimed],
                  page: page,
                  sort: sort)
    end

    begin
      total = response.results.total
      total_for_pages = page[:cursor].nil? ? [total.to_f, 10000].min : total.to_f
      total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0

      created = total > 0 ? facet_by_year(response.response.aggregations.created.buckets) : nil
      sources = total > 0 ? facet_by_key(response.response.aggregations.sources.buckets) : nil
      users = total > 0 ? facet_by_id(response.response.aggregations.users.buckets) : nil
      claim_actions = total > 0 ? facet_by_key(response.response.aggregations.claim_actions.buckets) : nil
      states = total > 0 ? facet_by_key(response.response.aggregations.states.buckets) : nil

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number],
        created: created,
        sources: sources,
        users: users,
        "claimActions" => claim_actions,
        states: states,
      }.compact

      options[:links] = {
        self: request.original_url,
        next: response.results.blank? ? nil : request.base_url + "/claims?" + {
          query: params[:query],
          "page[number]" => page[:number] + 1,
          "page[size]" => page[:size],
          sort: params[:sort],
        }.compact.to_query,
      }.compact
      options[:is_collection] = true

      fields = fields_from_params(params)
      if fields
        render json: ClaimSerializer.new(response.results, options.merge(fields: fields)).serializable_hash.to_json, status: :ok
      else
        render json: ClaimSerializer.new(response.results, options).serializable_hash.to_json, status: :ok
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      Raven.capture_exception(e)

      message = JSON.parse(e.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message } }.to_json, status: :bad_request
    end
  end

  def create
    @claim = Claim.where(orcid: params.fetch(:claim, {}).fetch(:orcid, nil),
                         doi: params.fetch(:claim, {}).fetch(:doi, nil)).first
    exists = @claim.present?

    if exists
      authorize! :update, @claim
      @claim.assign_attributes(safe_params.slice(:source_id, :claim_action).merge({ aasm_state: "waiting" }))
    else
      @claim = Claim.new(safe_params)
      authorize! :new, @claim
      @claim.assign_attributes(safe_params)
    end

    if @claim.save
      @claim.queue_claim_job

      options = {}
      options[:include] = @include
      options[:is_collection] = false
      render json: ClaimSerializer.new(@claim, options).serializable_hash.to_json, status: :accepted
    else
      logger.error @claim.errors.inspect
      render json: serialize_errors(@claim.errors), include: @include, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    render json: @claim, status: :ok
  end

  def destroy
    if @claim.present?
      @claim.assign_attributes(claim_action: "delete", aasm_state: "waiting")

      if @claim.save
        @claim.queue_claim_job

        options = {}
        options[:include] = @include
        options[:is_collection] = false
        render json: ClaimSerializer.new(@claim, options).serializable_hash.to_json, status: :accepted
      else
        logger.error @claim.errors.inspect
        render json: serialize_errors(@claim.errors), include: @include, status: :unprocessable_entity
      end

    else
      render json: { errors: [{ status: 400, title: "An error occured." }] }, status: :bad_request
    end
  end

  protected
    def load_claim
      @claim = Claim.where(uuid: params[:id]).first

      fail ActiveRecord::RecordNotFound if @claim.blank?
    end

    def load_user
      return nil if params[:user_id].blank?

      @user = User.where(uid: params[:user_id]).first

      fail ActiveRecord::RecordNotFound if @user.blank?
    end

    def set_include
      if params[:include].present?
        @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
        @include = @include & [:user]
      else
        @include = [:user]
      end
    end

    def human_source_name(source_id)
      sources.fetch(source_id, nil)
    end

    def sources
      { "orcid_search" => "ORCID Search and Link",
        "orcid_update" => "ORCID Auto-Update" }
    end

  private
    def safe_params
      params.require(:claim).permit(:uuid, :orcid, :doi, :source_id, :claim_action)
    end
end
