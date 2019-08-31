class Api::V1::RandomController < Api::BaseController
  before_action :authenticate_user_from_token!
  load_and_authorize_resource Phrase

  def index
    phrase = Phrase.new
    response.headers['X-Consumer-Role'] = current_user && current_user.role || 'anonymous'

    render json: { phrase: phrase.string }.to_json
  end
end
