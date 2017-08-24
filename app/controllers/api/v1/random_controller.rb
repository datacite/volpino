class Api::V1::RandomController < Api::BaseController
  def index
    phrase = Phrase.new
    render json: { phrase: phrase.string }.to_json
  end
end
