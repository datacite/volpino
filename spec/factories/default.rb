FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Josiah Carberry{n}" }
    sequence(:authentication_token) { |n| "q9pWP8QxzkR24Mvs9BEy#{n}" }
    provider "orcid"
    sequence(:uid) { |n| "0000-0002-1825-000#{n}" }

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
    url 'http://search.labs.datacite.org'

    initialize_with { Service.where(name: name).first_or_initialize }
  end

  factory :tag do
    name 'search'
    title 'Search'

    initialize_with { Tag.where(name: name).first_or_initialize }
  end

  factory :deposit do
    uuid { SecureRandom.uuid }
    message_type "orcid_update"
    source_token "123"
    message { { "contributors" => [{ "pid" => "http://orcid.org/0000-0002-3546-1048" }] } }
  end

  factory :claim do
    uid "0000-0002-1825-0001"
    doi "10.5061/DRYAD.781PV"
    source_id "orcid_update"
  end
end
