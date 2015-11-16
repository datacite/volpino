FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Joe Smith#{n}" }
    sequence(:authentication_token) { |n| "q9pWP8QxzkR24Mvs9BEy#{n}" }
    provider "orcid"
    sequence(:uid) { |n| "0000-0002-1825-00#{n}" }

    factory :admin_user do
      role "admin"
      authentication_token "12345"
    end

    initialize_with { User.where(authentication_token: authentication_token).first_or_initialize }
  end

  factory :service do
    name 'search'
    title 'Search'
    redirect_uri 'http://search.labs.datacite.org/auth/jwt/callback'

    initialize_with { Service.where(name: name).first_or_initialize }
  end

  factory :claim do
    work_id '10.5061/DRYAD.781PV'

    user
    service
  end
end
