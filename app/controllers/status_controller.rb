class StatusController < ApplicationController
  def index
    Status.create(current_version: Volpino::VERSION) if Rails.env == "development" || Status.count == 0

    collection = Status.order("created_at DESC")
    @current_status = collection.first

    page = params[:page] || { number: 1, size: 1000 }
    @status = collection.page(page[:number]).per(page[:size])

    @process = SidekiqProcess.new

    if current_user.try(:is_admin?) && @current_status.outdated_version?
      flash.now[:alert] = "Your Volpino software is outdated, please install <a href='#{ENV['GITHUB_URL']}/releases'>version #{@current_status.current_version}</a>.".html_safe
      @flash = flash
    end
  end

  private

  def safe_params
    params.require(:status).permit(:current_version)
  end
end
