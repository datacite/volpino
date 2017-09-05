class Api::V1::RolesController < Api::BaseController
  def index
    @roles = Role.all
    render jsonapi: @roles[:data], meta: @roles[:meta]
  end

  def show
    @role = Role.where(id: params[:id])
    fail AbstractController::ActionNotFound unless @role.present?

    render jsonapi: @role[:data]
  end
end
