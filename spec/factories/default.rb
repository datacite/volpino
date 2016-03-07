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
    end

    initialize_with { User.where(api_key: api_key).first_or_initialize }
  end

  factory :service do
    name 'search'
    title 'Search'
    redirect_uri 'http://search.labs.datacite.org/auth/jwt/callback'
    url 'http://search.labs.datacite.org'

    initialize_with { Service.where(name: name).first_or_initialize }
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

    initialize_with { Claim.where(orcid: orcid).where(doi: doi).first_or_initialize }
  end
end
