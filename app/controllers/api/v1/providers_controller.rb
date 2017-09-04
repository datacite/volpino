class Api::V1::ProvidersController < Api::BaseController
  def index
    @providers = Provider.where(params)
    render jsonapi: @providers[:data], meta: @providers[:meta]
  end

  def show
    @provider = Provider.where(id: params[:id])
    fail AbstractController::ActionNotFound unless @provider.present?

    render jsonapi: @provider[:data]
  end
end
