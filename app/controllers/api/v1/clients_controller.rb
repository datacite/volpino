class Api::V1::ClientsController < Api::BaseController
  before_filter :authenticate_user_from_token!, :set_include

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = nil
    end
  end

  def index
    @clients = Client.where(params)
    render jsonapi: @clients[:data], meta: @clients[:meta], include: @include
  end

  def show
    @client = Client.where(id: params[:id])
    fail AbstractController::ActionNotFound unless @client.present?

    render jsonapi: @client[:data], include: @include
  end
end
