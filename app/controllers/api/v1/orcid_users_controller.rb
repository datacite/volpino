class Api::V1::OrcidUsersController < Api::BaseController
  def index
    @orcid_users = OrcidUser.where(params)
    render jsonapi: @orcid_users[:data], meta: @orcid_users[:meta]
  end

  # def show
  #   @orcid_users = OrcidUser.where(id: params[:id])
  #   fail AbstractController::ActionNotFound unless @orcid_user.present?
  #
  #   render jsonapi: @orcid_user[:data]
  # end
end
