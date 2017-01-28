class Api::V1::UsersController < Api::BaseController
  prepend_before_filter :load_user, only: [:show]

  def show
    render json: @user
  end

  def index
    from_date = params['from-created-date'].presence || '2015-11-01'
    until_date = params['until-created-date'].presence || Time.zone.now.to_date.iso8601
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 1000

    collection = User.where(created_at: from_date..until_date)
    collection = collection.query(params[:query]) if params[:query]
    @users = collection.is_public.ordered.page(page[:number]).per_page(page[:size])

    meta = { total: @users.total_entries, 'total-pages' => @users.total_pages, page: page[:number].to_i }
    render json: @users, meta: meta
  end

  protected

  def load_user
    @user = User.where(uid: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @user.present?
  end
end
