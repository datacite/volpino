class StatusController < ApplicationController
  def index
    Status.create(current_version: Volpino::VERSION) if Rails.env == "development" || Status.count == 0

    collection = Status.order("created_at DESC")
    @current_status = collection.first

    page = params[:page] || { number: 1, size: 1000 }
    @status = collection.page(page[:number]).per(page[:size])

    @process = SidekiqProcess.new
  end

  private

  def safe_params
    params.require(:status).permit(:current_version)
  end
end
