module Api
  module V1
    class TasksController < ApplicationController
      before_action :doorkeeper_authorize!
      respond_to :json

      def index
        user = User.find(doorkeeper_token.resource_owner_id)
        respond_with user.tasks
      end

      def create
        respond_with Task.create(params[:task])
      end

      private

      def current_user
        @current_user ||= User.find(doorkeeper_token.resource_owner_id)
      end
    end
  end
end
