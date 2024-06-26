# frozen_string_literal: true

class UsersController < BaseController
  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for metadata lookup from ORCID
  include Metadatable

  # include helper module for information about associated DOIs
  include Countable

  prepend_before_action :load_user, only: %i[show destroy]
  before_action :set_include, :authenticate_user_from_token!
  load_and_authorize_resource only: [:destroy]

  def show
    options = {}

    meta = get_meta(user_id: params[:id])
    options[:meta] = {
      dois: meta.fetch("created", []),
      published: meta.fetch("published", []),
      "resourceTypes" => meta.fetch("resourceTypes", []),
      views: meta.fetch("views", []),
      downloads: meta.fetch("downloads", []),
      citations: meta.fetch("citations", []),
    }.compact
    options[:include] = @include
    options[:is_collection] = false
    options[:params] = { current_ability: current_ability }

    render json: UserSerializer.new(@user, options).serializable_hash.to_json, status: :ok
  end

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: "desc" } }
           when "name" then { "family_name.raw" => { order: "asc" } }
           when "-name" then { "family_name.raw" => { order: "desc" } }
           when "created" then { created_at: { order: "asc" } }
           when "-created" then { created_at: { order: "desc" } }
           else { "family_name.raw" => { order: "asc" } }
    end

    page = page_from_params(params)

    response = if params[:id].present?
      User.find_by(id: params[:id])
    elsif params[:ids].present?
      User.find_by_id(params[:ids], page: page, sort: sort)
    else
      User.query(params[:query], page: page, sort: sort)
    end

    begin
      total = response.results.total
      total_for_pages = page[:cursor].nil? ? [total.to_f, 10000].min : total.to_f
      total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number],
      }.compact

      options[:links] = {
        self: request.original_url,
        next: response.results.blank? ? nil : request.base_url + "/users?" + {
          query: params[:query],
          "page[number]" => page[:number] + 1,
          "page[size]" => page[:size],
          sort: params[:sort],
        }.compact.to_query,
      }.compact
      options[:is_collection] = true

      fields = fields_from_params(params)
      if fields
        render json: UserSerializer.new(response.results, options.merge(fields: fields)).serializable_hash.to_json, status: :ok
      else
        render json: UserSerializer.new(response.results, options).serializable_hash.to_json, status: :ok
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      Raven.capture_exception(e)

      message = JSON.parse(e.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message } }.to_json, status: :bad_request
    end
  end

  def create
    @user = User.new(safe_params)
    authorize! :create, @user

    if @user.save
      options = {}
      options[:is_collection] = false
      render json: UserSerializer.new(@user, options).serializable_hash.to_json, status: :created
    else
      logger.error @user.errors.inspect
      render json: serialize_errors(@user.errors), status: :unprocessable_entity
    end
  end

  def update
    @user = User.where(uid: params[:id]).first
    exists = @user.present?

    if exists
      authorize! :update, @user
      @user.assign_attributes(safe_params)
      status = :ok
    else
      @user = User.new(safe_params.merge(uid: params[:id], provider: "globus"))
      authorize! :new, @user
      status = :created
    end

    if @user.save
      options = {}
      options[:is_collection] = false
      render json: UserSerializer.new(@user, options).serializable_hash.to_json, status: status
    else
      logger.error @user.errors.inspect
      render json: serialize_errors(@user.errors), status: :unprocessable_entity
    end
  end

  def destroy; end

  protected
    def load_user
      @user = User.where(uid: params[:id]).first
      fail ActiveRecord::RecordNotFound if @user.blank?
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
      fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" if params[:data].blank?

      ActiveModelSerializers::Deserialization.jsonapi_parse!(
        params,
        only: [
          :id, :uid, :name, "givenNames", "familyName", :email, :beta_tester, :role, :provider, :client
        ],
        keys: {
          id: :uid, "givenNames" => :given_names, "familyName" => :family_name
        },
      )
    end
end
