class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new(:role => "anonymous") # Guest user

    if user.role == "staff_admin"
      can :manage, :all
    elsif user.role == "staff_user"
      can :read, :all
      can [:update], User, :id => user.id
    elsif user.role == "member_admin"
      can [:read], Phrase
      can [:read], User
      can [:update], User, :id => user.id
      can [:manage], Claim, :orcid => user.uid
      can [:update, :show], Member, :id => user.member_id
    elsif user.role == "member_user"
      can [:read], Phrase
      can [:read], User
      can [:update], User, :id => user.id
      can [:manage], Claim, :orcid => user.uid
      can [:read], Member, :id => user.member_id
    elsif user.role == "user"
      can [:read], Phrase
      can [:read], Claim
      can [:manage], Claim, :orcid => user.uid
      can [:update, :show], User, :id => user.id
    end
  end
end
