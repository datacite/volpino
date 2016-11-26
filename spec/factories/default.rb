FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Josiah Carberry{n}" }
    sequence(:api_key) { |n| "q9pWP8QxzkR24Mvs9BEy#{n}" }
    provider "orcid"
    role "user"
    sequence(:uid) { |n| "0000-0002-1825-000#{n}" }

    factory :admin_user do
      role "admin"
      api_key "12345"
      uid "0000-0002-1825-0003"
    end

    factory :staff_user do
      role "staff"
      uid "0000-0002-1825-0004"
    end

    factory :regular_user do
      role "user"
      uid "0000-0002-1825-0001"
    end

    factory :valid_user do
      uid '0000-0001-6528-2027'
      authentication_token ENV['ACCESS_TOKEN']
    end

    factory :invalid_user do
      uid '0000-0001-6528-2027'
      authentication_token nil
    end

    initialize_with { User.where(uid: uid).first_or_initialize }
  end

  factory :service do
    name 'search'
    title 'Search'
    redirect_uri 'http://search.labs.datacite.org/auth/jwt/callback'
    url 'http://search.labs.datacite.org'

    initialize_with { Service.where(name: name).first_or_initialize }
  end

  factory :member do
    name 'ANDS'
    title 'Australian National Data Service (ANDS)'
    country_code 'AU'
    year 2009

    initialize_with { Member.where(name: name).first_or_initialize }
  end

  factory :tag do
    name 'search'
    title 'Search'

    initialize_with { Tag.where(name: name).first_or_initialize }
  end

  factory :claim do
    uuid { SecureRandom.uuid }
    orcid "0000-0002-1825-0001"
    doi "10.5061/DRYAD.781PV"
    source_id "orcid_update"

    # association :user, factory: :user

    initialize_with { Claim.where(orcid: orcid).where(doi: doi).first_or_initialize }
  end
end
