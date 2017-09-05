class Api::V1::UsersController < Api::BaseController
  prepend_before_filter :load_user, only: [:show, :update, :destroy]
  before_filter :set_include, :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :create]

  def show
    render jsonapi: @user, include: @include
  end

  def index
    collection = User

    if params[:id].present?
      collection = collection.where(name: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    # filter by current user, provider or client
    if params['provider-id'].present?
      collection = collection.where(provider_id: params['provider-id'])
    elsif params['client-id'].present?
      collection = collection.where(client_id: params['client-id'])
    elsif current_user.present?
      collection = collection.where(provider_id: current_user.provider_id) if current_user.provider_id.present?
      collection = collection.where(client_id: current_user.client_id) if current_user.client_id.present?
    else
      collection = collection.is_public
    end

    collection = collection.where(role_id: params['role-id']) if params['role-id'].present?

    if params['from-created-date'].present? || params['until-created-date'].present?
      from_date = params['from-created-date'].presence || '2015-11-01'
      until_date = params['until-created-date'].presence || Time.zone.now.to_date.iso8601
      collection = collection.where(created_at: from_date..until_date)
    end

    if current_user.blank?
      roles = nil
    elsif  params['role-id'].present?
      roles = [{ id: params['role-id'],
                 title: cached_role_response(params['role-id']).name,
                 count: collection.where(role_id: params['role-id']).count }]
    else
      roles = collection.where.not(role_id: nil).group(:role_id).count
      roles = roles.map { |k,v| { id: k, title: k.titleize, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25

    @users = collection.is_public.order_by_name.page(page[:number]).per_page(page[:size])

    meta = { total: @users.total_entries,
             total_pages: @users.total_pages,
             page: page[:number].to_i,
             roles: roles }.compact

    render jsonapi: @users, meta: meta, include: @include
  end

  def update
    Rails.logger.info safe_params.inspect
    @user.update_attributes(safe_params)

    render jsonapi: @user, include: @include
  end

  def destroy

  end

  protected

  def load_user
    @user = User.is_public.where(uid: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @user.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ['role', 'client', 'provider']
    end
  end

  private

  def safe_params
    Rails.logger.info params.inspect
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:credit_name, :given_names, :family_name, :email, :role, :provider, :client],
              keys: { credit_name: :name }
    )
  end
end
