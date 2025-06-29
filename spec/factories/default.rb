# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:name) { |_n| "Josiah Carberry{n}" }
    provider { "globus" }
    role_id { "user" }
    sequence(:uid) { |n| "0000-0002-1825-000#{n}" }

    factory :admin_user do
      role_id { "staff_admin" }
      uid { "0000-0002-1825-0003" }
    end

    factory :staff_user do
      role_id { "staff_user" }
      uid { "0000-0002-1825-0004" }
    end

    factory :regular_user do
      role_id { "user" }
      uid { "0000-0002-1825-0001" }
    end

    factory :valid_user do
      uid { "0000-0001-6528-2027" }
      orcid_token { ENV["ORCID_TOKEN"] }
      orcid_auto_update_access_token { "TEST_AUTO_UPDATE_TOKEN" }
      orcid_search_and_link_access_token { "TEST_SEARCH_AND_LINK_TOKEN" }
    end

    factory :invalid_user do
      uid { "0000-0001-6528-2027" }
      orcid_token { nil }
      orcid_auto_update_access_token { nil }
      orcid_search_and_link_access_token { nil }
    end

    initialize_with { User.where(uid: uid).first_or_initialize }
  end

  factory :claim do
    user

    uuid { SecureRandom.uuid }
    orcid { user.uid }
    doi { "10.5061/DRYAD.781PV" }
    source_id { "orcid_update" }

    initialize_with { Claim.where(orcid: orcid).where(doi: doi).first_or_initialize }
  end
end
