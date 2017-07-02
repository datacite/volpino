class UsersController < ApplicationController
  before_filter :load_user, only: [:show, :edit, :destroy]
  load_and_authorize_resource

  def show
    @title = 'Settings'
    respond_to do |format|
      format.js { render @panel }
      format.html
    end
  end

  def index
    load_index
  end

  def edit
    if params[:panel].present?
      # user updates his account
      render @panel
    else
      # admin updates user account
      @user = User.find(params[:id])
      load_index
      render :index
    end
  end

  def update
    if params[:panel].present?
      # user updates his account

      load_user

      @user.update_attributes(safe_params)

      # delete GitHub external identifier from ORCID if GitHub account is unlinked
      GithubJob.perform_later(@user) if @user.github_uid.blank? && @user.github_put_code.present?

      render @panel
    else
      # admin updates user account
      @user = User.find(params[:id])
      @user.update_attributes(safe_params)

      load_index
      render :index
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    load_index
    render :index
  end

  protected

  def load_user
    if user_signed_in?
      @user = current_user
      @member = @user.member

      panels = %w(auto public login account orcid impactstory)
      @panel = panels.find { |p| p == params[:panel] } || "account"
    else
      fail CanCan::AccessDenied.new("Please sign in first.", :read, User)
    end
  end

  def load_index
    collection = User

    if params[:member_id]
      collection = collection.where(:member_id => params[:member_id])
    end

    case params[:contact_type]
    when "voting_contact"
      collection = collection.where(is_voting_contact: true)
      @contact_type = ["voting_contact", User.where(is_voting_contact: true).count]
    when "billing_contact"
      collection = collection.where(is_billing_contact: true)
      @contact_type = ["billing_contact", User.where(is_billing_contact: true).count]
    when "business_contact"
      collection = collection.where(is_business_contact: true)
      @contact_type = ["business_contact", User.where(is_business_contact: true).count]
    when "technical_contact"
      collection = collection.where(is_technical_contact: true)
      @contact_type = ["technical_contact", User.where(is_technical_contact: true).count]
    when "metadata_contact"
      collection = collection.where(is_metadata_contact: true)
      @contact_type = ["metadata_contact", User.where(is_metadata_contact: true).count]
    end

    if params[:organization]
      collection = collection.where(:organization => params[:organization])
      @organization = User.where(organization: params[:organization]).group(:organization).count.first
    end

    if params[:role]
      collection = collection.where(:role => params[:role])
      @role = User.where(role: params[:role]).group(:role).count.first
    end

    collection = collection.query(params[:query]) if params[:query]
    collection = collection.ordered

    @contact_types = [
      ["voting_contact", User.where(is_voting_contact: true).count],
      ["billing_contact", User.where(is_billing_contact: true).count],
      ["business_contact", User.where(is_business_contact: true).count],
      ["technical_contact", User.where(is_technical_contact: true).count],
      ["metadata_contact", User.where(is_metadata_contact: true).count],
    ].select { |contact| contact.last > 0 }
    @organizations = User.group(:organization).count
    @roles = User.group(:role).count
    @users = collection.paginate(:page => params[:page])
  end

  private

  def safe_params
    params.require(:user).permit(:name,
                                 :email,
                                 :unconfirmed_email,
                                 :auto_update,
                                 :role,
                                 :is_voting_contact,
                                 :is_billing_contact,
                                 :is_business_contact,
                                 :is_technical_contact,
                                 :is_metadata_contact,
                                 :is_public,
                                 :member_id,
                                 :datacenter_id,
                                 :expires_at,
                                 :facebook_uid,
                                 :facebook_token,
                                 :google_uid,
                                 :google_token,
                                 :github,
                                 :github_uid,
                                 :github_token,
                                 :authentication_token)
  end
end
