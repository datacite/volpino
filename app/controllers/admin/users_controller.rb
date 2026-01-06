# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    # include base controller methods
    include Authenticable

    before_action :load_user, only: %i[edit update destroy]
    load_and_authorize_resource except: [:index]

    def index
      load_index

      render :index
    end

    def edit
      load_index

      render :edit
    end

    def update
      # admin updates user account
      @user.update(safe_params)

      load_index
      render :edit
    end

    def destroy
      @user.destroy
      load_index
      render :index
    end

    protected
      def load_user
        if user_signed_in?
          @user = User.where(uid: params[:id]).first
        else
          fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
        end
      end

      def load_index
        authorize! :manage, User

        sort = case params[:sort]
               when "relevance" then { "_score" => { order: "desc" } }
               when "name" then { "family_name.raw" => { order: "asc" } }
               when "-name" then { "family_name.raw" => { order: "desc" } }
               when "created" then { created_at: { order: "asc" } }
               when "-created" then { created_at: { order: "desc" } }
               else { "family_name.raw" => { order: "asc" } }
        end

        @page = params[:page] || 1

        response = User.query(params[:query],
                              created: params[:created],
                              role_id: params[:role_id],
                              page: { number: @page },
                              sort: sort)

        @total = response.results.total
        @users = response.results

        @created = @total > 0 ? facet_by_year(response.response.aggregations.created.buckets) : nil
        @roles = @total > 0 ? facet_by_key(response.response.aggregations.roles.buckets) : nil
      end

    private
      def safe_params
        params.require(:user).permit(:name,
                                    :email,
                                    :auto_update,
                                    :role_id,
                                    :is_public,
                                    :beta_tester,
                                    :provider_id,
                                    :client_id,
                                    :expires_at,
                                    :orcid_token,
                                    :orcid_expires_at,
                                    :github,
                                    :github_uid,
                                    :github_token,
                                    :authentication_token)
      end
  end
end
