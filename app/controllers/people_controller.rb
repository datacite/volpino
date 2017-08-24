class PeopleController < Api::BaseController
  prepend_before_filter :load_user, only: [:show]

  def show
    render json: @user, serializer: PersonSerializer
  end

  def index
    collection = User.is_public

    if params[:id].present?
      collection = collection.where(name: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    collection = collection.where(role: params[:role]) if params[:role].present?

    if params['from-created-date'].present? || params['until-created-date'].present?
      from_date = params['from-created-date'].presence || '2015-11-01'
      until_date = params['until-created-date'].presence || Time.zone.now.to_date.iso8601
      collection = collection.where(created_at: from_date..until_date)
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25

    @users = collection.order_by_name.page(page[:number]).per_page(page[:size])

    meta = { total: @users.total_entries,
             total_pages: @users.total_pages,
             page: page[:number].to_i }.compact

    render json: @users, meta: meta, each_serializer: PersonSerializer
  end

  protected

  def load_user
    @user = User.is_public.where(uid: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @user.present?
  end
end
