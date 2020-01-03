class UsersController < BaseController
  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for metadata lookup from ORCID
  include Metadatable

  # include helper module for information about associated DOIs
  include Countable

  prepend_before_action :load_user, only: [:show, :destroy]
  before_action :set_include, :authenticate_user_from_token!
  load_and_authorize_resource :only => [:destroy]

  def show
    options = {}

    meta = get_meta(user_id: params[:id])
    options[:meta] = {
      dois: meta.fetch("created", []),
      published: meta.fetch("published", []),
      "resourceTypes" => meta.fetch("resourceTypes", []) }.compact
    options[:include] = @include
    options[:is_collection] = false
    options[:params] = { current_ability: current_ability }

    render json: UserSerializer.new(@user, options).serialized_json, status: :ok
  end

  def index
    sort = case params[:sort]
    when "relevance" then { "_score" => { order: 'desc' }}
    when "name" then { "family_name.raw" => { order: 'asc' }}
    when "-name" then { "family_name.raw" => { order: 'desc' }}
    when "created" then { created_at: { order: 'asc' }}
    when "-created" then { created_at: { order: 'desc' }}
    else { "family_name.raw" => { order: 'asc' }}
    end

    page = page_from_params(params)

    if params[:id].present?
      response = User.find_by_id(params[:id])
    elsif params[:ids].present?
      response = User.find_by_id(params[:ids], page: page, sort: sort)
    else
      response = User.query(params[:query], page: page, sort: sort)
    end

    begin
      total = response.results.total
      total_for_pages = page[:cursor].nil? ? [total.to_f, 10000].min : total.to_f
      total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number]
      }.compact

      options[:links] = {
      self: request.original_url,
      next: response.results.blank? ? nil : request.base_url + "/users?" + {
        query: params[:query],
        "page[number]" => page[:number] + 1,
        "page[size]" => page[:size],
        sort: params[:sort] }.compact.to_query
      }.compact
      options[:is_collection] = true

      fields = fields_from_params(params)
      if fields
        render json: UserSerializer.new(response.results, options.merge(fields: fields)).serialized_json, status: :ok
      else
        render json: UserSerializer.new(response.results, options).serialized_json, status: :ok
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Raven.capture_exception(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def create
    @user = User.new(safe_params)
    authorize! :create, @user

    if @user.save
      options = {}
      options[:is_collection] = false
      render json: UserSerializer.new(@user, options).serialized_json, status: :created
    else
      logger.error @user.errors.inspect
      render json: serialize_errors(@user.errors), status: :unprocessable_entity
    end
  end

  def update
    @user = User.where(uid: params[:id]).first

    unless @user.present?
      metadata = UsersController.get_orcid_metadata(params[:id])
      fail ActiveRecord::RecordNotFound unless metadata.present?

      @user = User.from_omniauth(nil, provider: "globus", uid: params[:id])
    else
      metadata = {}
    end

    authorize! :update, @user

    if @user.update_attributes(safe_params.merge(metadata))
      options = {}
      options[:is_collection] = false
      render json: UserSerializer.new(@user, options).serialized_json, status: :ok
    else
      logger.error @user.errors.inspect
      render json: serialize_errors(@user.errors), status: :unprocessable_entity
    end
  end

  def destroy

  end

  protected

  def load_user
    @user = User.where(uid: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @user.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = @include & [:claims]
    else
      @include = []
    end
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params,
      only: [
        :id, :uid, :name, "givenNames", "familyName", :email, :beta_tester, :role, :provider, :client
      ],
      keys: {
        id: :uid, "givenNames" => :given_names, "familyName" => :family_name
      }
    )
  end
end
