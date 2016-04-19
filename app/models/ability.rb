class Ability
  include CanCan::Ability

  # To simplify, all admin permissions are linked to the Notification resource

  def initialize(user)
    user ||= User.new(:role => "anonymous") # Guest user

    if user.role == "admin"
      can :manage, :all
    elsif user.role == "staff"
      can :read, :all
      can [:update, :show], User, :id => user.id
    elsif user.role == "member"
      can [:read], User
      can [:update, :show], User, :id => user.id
      can [:update, :show], Member, :id => user.member_id
    elsif user.role == "user"
      can [:read], Claim
      can [:read], User
      can [:manage], Claim, :orcid => user.uid
      can [:update, :show], User, :id => user.id
    end
  end
end
