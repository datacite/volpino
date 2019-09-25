class RolesController < BaseController
  def index
    @roles = Role.where(params)
    render jsonapi: @roles[:data], meta: @roles[:meta]
  end

  def show
    @role = Role.where(id: params[:id])
    fail AbstractController::ActionNotFound unless @role.present?

    render jsonapi: @role[:data]
  end
end
