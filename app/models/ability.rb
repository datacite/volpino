class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new(:role_id => "anonymous") # Guest user

    if user.role_id == "staff_admin"
      can :manage, :all
    elsif user.role_id == "staff_user"
      can :read, :all
      can [:update], User, :id => user.id
    elsif user.role_id == "provider_admin"
      can [:read], Phrase
      can [:read], User
      can [:update], Member, :name => user.provider_id
      can [:update], User, :id => user.id
      can [:manage], Claim, :orcid => user.uid
    elsif user.role_id == "provider_user"
      can [:read], Phrase
      can [:read], User
      can [:read], Member, :name => user.provider_id
      can [:update], User, :id => user.id
      can [:manage], Claim, :orcid => user.uid
    elsif user.role_id == "client_admin"
      can [:read], Phrase
      can [:read], User
      can [:update], User, :id => user.id
      can [:manage], Claim, :orcid => user.uid
    elsif user.role_id == "client_user"
      can [:read], Phrase
      can [:read], User
      can [:update], User, :id => user.id
      can [:manage], Claim, :orcid => user.uid
    elsif user.role_id == "user"
      can [:read], Phrase
      can [:read], Claim
      can [:manage], Claim, :orcid => user.uid
      can [:update, :show], User, :id => user.id
    end
  end
end
