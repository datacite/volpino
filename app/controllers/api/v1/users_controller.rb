class Api::V1::UsersController < Api::BaseController
  # include helper module for caching infrequently changing resources
  include Cacheable

  prepend_before_filter :load_user, only: [:show, :update, :destroy]
  before_filter :set_include, :authenticate_user_from_token!
  load_and_authorize_resource :only => [:destroy]

  def show
    render jsonapi: @user, include: @include, serializer: UserSerializer
  end

  def index
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25

    if params.has_key?(:registry)
      user_search = UserSearch.where(params.merge(page: page)).to_h
      collection = user_search.fetch(:data, [])
      @users = Kaminari.paginate_array(collection).page(page[:number]).per(page[:size])

      total = user_search.dig(:meta, :total)
      total_pages = (total.to_f / page[:size]).ceil
      roles = nil
    else
      collection = User

      if params[:id].present?
        collection = collection.where(name: params[:id])
      elsif params[:query].present?
        collection = collection.query(params[:query])
      end

      collection = collection.is_public if current_user.blank?

      # exclude users from search result, needed to manage users by provider
      if params.has_key?(:exclude) && params[:provider_id].present?
        collection = collection.where('provider_id IS NULL OR provider_id != ?', params[:provider_id])
      elsif params[:provider_id].present?
        collection = collection.where(provider_id: params[:provider_id])
      end

      # exclude users from search result, needed to manage users by client
      if params.has_key?(:exclude) && params[:client_id].present?
        provider_id = params[:client_id].split('.').first
        collection = collection.where(provider_id: provider_id).where('client_id IS NULL OR client_id != ?', params[:client_id])
      elsif params[:client_id].present?
        collection = collection.where(client_id: params[:client_id])
      end

      if params[:sandbox_id].present?
        collection = collection.where(sandbox_id: params[:sandbox_id])
      elsif params.has_key?(:exclude) && params.has_key?(:sandbox)
        collection = collection.where(sandbox_id: nil)
      elsif params.has_key?(:sandbox)
        collection = collection.where.not(sandbox_id: nil)
      end

      collection = collection.where(role_id: params[:role_id]) if params[:role_id].present?

      if params[:from_created_date].present? || params[:until_created_date].present?
        from_date = params[:from_created_date].presence || '2015-11-01'
        until_date = params[:until_created_date].presence || Time.zone.now.to_date.iso8601
        collection = collection.where(created_at: from_date..until_date)
      end

      if current_user.blank?
        roles = nil
      elsif  params[:role_id].present?
        roles = [{ id: params[:role_id],
                   title: cached_role_response(params[:role_id]).name,
                   count: collection.where(role_id: params[:role_id]).count }]
      else
        roles = collection.where.not(role_id: nil).group(:role_id).count
        roles = roles.map { |k,v| { id: k, title: k.titleize, count: v } }
      end

      total = collection.count
      total_pages = collection.page(1).total_pages

      order = case params[:sort]
                when "-name" then "users.family_name DESC"
                when "created" then "users.created_at"
                when "-created" then "users.created_at DESC"
                else "ISNULL(users.family_name), users.family_name"
              end

      @users = collection.is_public.order(order).page(page[:number]).per(page[:size])
    end

    meta = { total: total,
             total_pages: total_pages,
             page: page[:number].to_i,
             roles: roles }.compact

    render jsonapi: @users, meta: meta, include: @include, each_serializer: UserSerializer
  end

  def update
    if @user.created_at.present?
      authorize! :update, @user

      if @user.update_attributes(safe_params)
        render jsonapi: @user, include: @include
      else
        Rails.logger.warn @user.errors.inspect
        render json: @user, status: 422, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    else
      @user = User.new(safe_params)
      authorize! :create, @user

      if @user.save
        render jsonapi: @user, include: @include
      else
        Rails.logger.warn @user.errors.inspect
        render json: @user, status: 422, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end
  end

  def destroy

  end

  protected

  def load_user
    if current_user.present?
      @user = User.where(uid: params[:id]).first
    else
      @user = User.is_public.where(uid: params[:id]).first
    end

    @user = UserSearch.where(id: params[:id]).to_h.fetch(:data, nil) unless @user.present?
    fail ActiveRecord::RecordNotFound unless @user.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ['role', 'client', 'provider', 'sandbox']
    end
  end

  private

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:uid, :name, :given_names, :family_name, :email, :beta_tester, :role, :provider, :sandbox, :client]
    )
  end
end
