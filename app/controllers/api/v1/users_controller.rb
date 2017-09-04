class Api::V1::UsersController < Api::BaseController
  prepend_before_filter :load_user, only: [:show, :destroy]
  before_filter :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :create]

  def show
    render json: @user
  end

  def index
    collection = User

    if params[:id].present?
      collection = collection.where(name: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    # filter by current user
    if current_user.present?
      provider_id = current_user.provider_id.presence || params['provider-id']
      collection = collection.where(provider_id: provider_id) if provider_id.present?

      client_id = current_user.client_id.presence  || params['client-id']
      collection = collection.where(client_id: client_id) if client_id.present?
    else
      collection = collection.is_public
    end

    collection = collection.where(role: params[:role]) if params[:role].present?

    if params['from-created-date'].present? || params['until-created-date'].present?
      from_date = params['from-created-date'].presence || '2015-11-01'
      until_date = params['until-created-date'].presence || Time.zone.now.to_date.iso8601
      collection = collection.where(created_at: from_date..until_date)
    end

    if current_user.blank?
      roles = nil
    elsif  params[:role].present?
      roles = [{ id: params[:role],
                 title: params[:role].humanize,
                 count: collection.where(role: params[:role]).count }]
    else
      roles = collection.where.not(role: nil).group(:role).count
      roles = roles.map { |k,v| { id: k, title: k.titleize, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25

    @users = collection.is_public.order_by_name.page(page[:number]).per_page(page[:size])
    @include = ['provider', 'client']

    meta = { total: @users.total_entries,
             total_pages: @users.total_pages,
             page: page[:number].to_i,
             roles: roles }.compact

    render json: @users, meta: meta, include: @include
  end

  protected

  def load_user
    @user = User.is_public.where(uid: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @user.present?
  end
end
